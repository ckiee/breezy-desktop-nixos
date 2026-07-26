flake:

{ config, lib, pkgs, ... }:

let
  cfg = config.services.breezy-desktop;
  packages = flake.packages.${pkgs.system};
in
{
  options.services.breezy-desktop = {
    enable = lib.mkEnableOption "Breezy Desktop XR support";

    gnome.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install the GNOME shell extension and UI app for Breezy Desktop.";
    };

    kwin.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install the KWin effect plugin for Breezy Desktop.";
    };

    vulkan.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install the Vulkan post-processing layer for XR gaming.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Load uinput kernel module (required for input device emulation)
    boot.kernelModules = [ "uinput" ];

    # Install udev rules for XR device access
    services.udev.packages = [ packages.xr-linux-driver ];

    # Clean up stale shared memory file on boot (may be owned by sddm)
    systemd.tmpfiles.rules = [
      "r! /dev/shm/xr_driver_state"
    ];

    # Systemd user service for the XR driver
    systemd.user.services.xr-driver = {
      description = "XR user-space driver";
      after = [ "network.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${packages.xr-linux-driver}/bin/xrDriver";
        Environment = "LD_LIBRARY_PATH=${packages.xr-linux-driver}/lib";
        Restart = "always";
      };
    };

    # Always install the driver CLI
    environment.systemPackages = [
      packages.xr-linux-driver
    ]
    ++ lib.optionals cfg.gnome.enable [
      packages.breezy-desktop-ui
      packages.breezy-gnome
    ]
    ++ lib.optionals cfg.kwin.enable [
      packages.breezy-kwin
      packages.breezy-desktop-ui
      pkgs.kdePackages.qtquick3d  # QML modules needed by the KWin effect at runtime
    ]
    ++ lib.optionals cfg.vulkan.enable [
      packages.breezy-vulkan
    ];

    # Vulkan layer: make it discoverable via implicit layer path
    environment.sessionVariables = lib.mkIf cfg.vulkan.enable {
      VK_LAYER_PATH = lib.mkDefault "${packages.breezy-vulkan}/share/vulkan/implicit_layer.d";
    };
  };
}
