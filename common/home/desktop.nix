{
  inputs,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # basic dev
    gh
    neovim
    ripgrep
    cmake
    clang_20
    ninja
    python313
    meson
    unzip
    jetbrains.idea
    jetbrains.webstorm

    # ai
    (inputs.kimi-code.packages.${pkgs.stdenv.system}.default)
    opencode

    # rust dev
    (rust-bin.stable."1.90.0".default.override {
      extensions = [ "rust-analyzer" "rust-src" ];
    })

    # apps
    zed-editor
    signal-desktop
    mpv

    # parsec-bin
    obsidian

    # ios
    libimobiledevice
  ];
}
