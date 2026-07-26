# breezy-desktop-nixos

I recently acquired a set of [Viture](https://www.viture.com/) Pro XR Glasses and wanted to use them on [NixOS](https://nixos.org) so here is the result of that work.

Nix flake packaging for [Breezy Desktop](https://github.com/wheaney/breezy-desktop) — an XR productivity and gaming suite for Linux. This flake provides NixOS packages, a NixOS module, and an overlay for all Breezy Desktop components.

## Packages

| Package | Description |
|---------|-------------|
| `xr-linux-driver` | Core XR user-space driver (C/Rust) with udev rules and systemd service |
| `breezy-desktop-ui` | GTK4/libadwaita settings app |
| `breezy-gnome` | GNOME Shell extension |
| `breezy-kwin` | KDE Plasma 6 KWin effect plugin |
| `breezy-vulkan` | Vulkan post-processing layer for XR gaming |

## Installation

### As a NixOS module (recommended)

Add the flake to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    breezy-desktop.url = "github:johnrizzo1/breezy-desktop-nixos";
  };

  outputs = { nixpkgs, breezy-desktop, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        breezy-desktop.nixosModules.breezy-desktop
        {
          services.breezy-desktop = {
            enable = true;

            # Pick your desktop environment:
            gnome.enable = true;   # GNOME Shell extension + UI
            # kwin.enable = true;  # KDE Plasma 6 KWin plugin + UI

            # Optional:
            # vulkan.enable = true; # Vulkan layer for XR gaming
          };
        }
      ];
    };
  };
}
```

### Using the overlay

```nix
{
  nixpkgs.overlays = [ breezy-desktop.overlays.default ];
}
```

This makes all packages available as `pkgs.xr-linux-driver`, `pkgs.breezy-gnome`, etc.

### Building individual packages

```sh
nix build .#xr-linux-driver
nix build .#breezy-desktop-ui
nix build .#breezy-gnome
nix build .#breezy-kwin
nix build .#breezy-vulkan
```

## Supported platforms

- `x86_64-linux`
- `aarch64-linux`

## Development

```sh
# Clone the repository
git clone https://github.com/johnrizzo1/breezy-desktop-nixos.git
cd breezy-desktop-nixos

# Build all packages
nix build .#xr-linux-driver
nix build .#breezy-desktop-ui
nix build .#breezy-gnome
nix build .#breezy-vulkan
nix build .#breezy-kwin

# Check the flake
nix flake check
```

Package sources are in `pkgs/` and the NixOS module is in `modules/breezy-desktop.nix`.

## Upstream projects

- [breezy-desktop](https://github.com/wheaney/breezy-desktop) — Main project and UI app
- [XRLinuxDriver](https://github.com/wheaney/XRLinuxDriver) — Core XR driver
- [breezy-desktop-gnome-ext](https://github.com/wheaney/breezy-desktop-gnome-ext) — GNOME Shell extension
- [breezy-desktop-kwin-effect](https://github.com/wheaney/breezy-desktop-kwin-effect) — KWin effect plugin
- [breezy_vulkan](https://github.com/wheaney/breezy_vulkan) — Vulkan layer (vkBasalt fork)

## License

See upstream projects for licensing details.
