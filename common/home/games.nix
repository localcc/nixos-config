{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    (prismlauncher.override {
      jdks = [
        javaPackages.compiler.temurin-bin.jre-21
        javaPackages.compiler.temurin-bin.jre-17
        javaPackages.compiler.temurin-bin.jre-11
        javaPackages.compiler.temurin-bin.jre-8
      ];
    })
    mangohud
    umu-launcher
    (lutris.override {
      extraLibraries = pkgs: [
      ];
      extraPkgs = pkgs: [
        pkgs.wineWowPackages.stagingFull
        pkgs.winetricks
      ];
    })
  ];
}
