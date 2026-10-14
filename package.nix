{
  lib,
  stdenv,
  rustPlatform,
  pkg-config,
  libxkbcommon,
  wayland,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxrandr,
  vulkan-loader,
  libGL,
  dbus,
  # The upstream source tree, supplied by the flake (the `vectorcraft-src` input).
  src,
}:

let
  # Everything below is derived from the source, so updating the flake input needs no edits here.
  workspaceVersion = (builtins.fromTOML (builtins.readFile "${src}/Cargo.toml")).workspace.package.version;
  # Flake inputs expose lastModifiedDate as YYYYMMDDHHMMSS.
  d = src.lastModifiedDate or "19700101000000";
  date = "${builtins.substring 0 4 d}-${builtins.substring 4 2 d}-${builtins.substring 6 2 d}";
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "vectorcraft";
  # The flake input follows upstream's default branch, so the commit date marks the snapshot.
  version = "${workspaceVersion}-unstable-${date}";

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  # Build only the desktop app and the CLI, as upstream's packaging/linux/package.sh does.
  # The workspace also contains a wasm app and xtask.
  cargoBuildFlags = [
    "--package"
    "vectorcraft"
    "--package"
    "vectorcraft-cli"
  ];

  nativeBuildInputs = [ pkg-config ];

  # winit, wgpu and rfd load these with dlopen at runtime, so they are not ELF NEEDED entries.
  # Upstream's own list is in packaging/linux/nfpm.yaml. They are added to the RPATH in
  # postFixup. rfd's xdg-portal backend dlopens libdbus-1.so.3: without it, Open/Save/Export
  # dialogs silently fail to appear.
  buildInputs = [
    libxkbcommon # also provides libxkbcommon-x11
    wayland
    libx11
    libxcb
    libxcursor
    libxi
    libxrandr
    vulkan-loader
    libGL # libEGL fallback when Vulkan is unavailable
    dbus
  ];

  # The test suite includes GPU/UI snapshot tests that don't work in the sandbox.
  doCheck = false;

  postInstall = ''

    install -Dm644 packaging/linux/ai.storyteller.vectorcraft.desktop \
      $out/share/applications/ai.storyteller.vectorcraft.desktop

    install -Dm644 packaging/linux/ai.storyteller.vectorcraft.mime.xml \
      $out/share/mime/packages/ai.storyteller.vectorcraft.xml

    mkdir -p $out/share/metainfo
    substitute packaging/linux/ai.storyteller.vectorcraft.metainfo.xml.in \
      $out/share/metainfo/ai.storyteller.vectorcraft.metainfo.xml \
      --subst-var-by VERSION "${workspaceVersion}" \
      --subst-var-by DATE "${date}"

    mkdir -p $out/share/icons
    cp -r assets/app-icon/hicolor $out/share/icons/
    
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    for b in vectorcraft vectorcraft-cli; do
      patchelf --add-rpath ${lib.makeLibraryPath finalAttrs.buildInputs} $out/bin/$b
    done
  '';

  meta = {
    description = "Native, open-source vector illustration editor written in Rust";
    homepage = "https://github.com/storytold/vectorcraft";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "vectorcraft";
    platforms = lib.platforms.linux;
  };
})
