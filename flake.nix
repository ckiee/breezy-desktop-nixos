{
  description = "Nix packages for breezy-desktop — XR productivity and gaming on Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      pkgsFor = system: import nixpkgs {
        inherit system;
        # Allow unfree for vendor SDK blobs (Viture, RayNeo, Rokid)
        config.allowUnfree = true;
      };

      version = "2.9.4";
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          xr-linux-driver = pkgs.callPackage ./pkgs/xr-linux-driver.nix {
            inherit version;
          };

          breezy-desktop-ui = pkgs.callPackage ./pkgs/breezy-desktop-ui.nix {
            inherit version;
          };

          breezy-gnome = pkgs.callPackage ./pkgs/breezy-gnome.nix {
            inherit version;
          };

          breezy-vulkan = pkgs.callPackage ./pkgs/breezy-vulkan.nix {
            inherit version;
          };

          breezy-kwin = pkgs.callPackage ./pkgs/breezy-kwin.nix {
            inherit version;
          };
        }
      );

      nixosModules.breezy-desktop = import ./modules/breezy-desktop.nix self;

      overlays.default = final: prev: {
        inherit (self.packages.${prev.system})
          xr-linux-driver
          breezy-desktop-ui
          breezy-gnome
          breezy-vulkan
          breezy-kwin;
      };
    };
}
