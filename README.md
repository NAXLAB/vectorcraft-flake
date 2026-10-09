# vectorcraft-flake

A Nix flake that packages [VectorCraft](https://github.com/storytold/vectorcraft), a native,
open-source vector illustration editor written in Rust.

The flake tracks upstream's default branch through a flake input. VectorCraft itself is
developed upstream.

## Usage

Run it without installing:

```sh
nix run github:NAXLAB/vectorcraft-flake        # the desktop app
nix run github:NAXLAB/vectorcraft-flake#cli    # vectorcraft-cli
```

### Install on NixOS

Add the flake as an input, and make sure your modules receive `inputs` (for example through
`specialArgs = { inherit inputs; };`):

```nix
# flake.nix
inputs.vectorcraft = {
  url = "github:NAXLAB/vectorcraft-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

```nix
# any module that takes `inputs` in its arguments
environment.systemPackages = [
  inputs.vectorcraft.packages.${pkgs.stdenv.hostPlatform.system}.default
];
```

Or use the overlay and write `pkgs.vectorcraft`:

```nix
nixpkgs.overlays = [ inputs.vectorcraft.overlays.default ];
environment.systemPackages = [ pkgs.vectorcraft ];
```

Open, Save and Export dialogs go through the XDG desktop portal, so you need a portal backend
that provides a file chooser (for example `xdg-desktop-portal-gnome` or
`xdg-desktop-portal-gtk`) and `hardware.graphics.enable = true` for Vulkan/EGL.

## What is in the package

- `vectorcraft` (desktop app) and `vectorcraft-cli` binaries.
- Desktop entry, MIME definitions, AppStream metadata and icons from upstream's
  `packaging/linux`.
- Runtime libraries (xkbcommon, Wayland, X11, Vulkan, EGL, libdbus) added to the binaries'
  RPATH, because winit, wgpu and rfd load them with `dlopen`.

## Limitations

- Tests are disabled: they need a GPU.
- The optional [craft-fonts](https://github.com/storytold/craft-fonts) input (bundled Japanese
  fonts) is not included; the app falls back to system CJK fonts.
- aarch64-linux is listed in the flake but untested.

## License

The packaging files in this repository are licensed under the [MIT License](LICENSE).

VectorCraft itself is dual-licensed under MIT or Apache-2.0 by its authors. Its ArtCraft name,
wordmark and logos are trademarks of the ArtCraft Team and are covered by upstream's own brand
license. VectorCraft is not affiliated with Adobe.
