{
  pkgs,
  inputs,
  ...
}:
let
  nixpkgs-graalvm = (
    import inputs.nixpkgs-graalvm {
      system = pkgs.stdenv.system;
      config.allowUnfree = true;
    }
  );
in
{
  home.packages = with pkgs; [
    (prismlauncher.override {
      jdks = [
        javaPackages.compiler.temurin-bin.jre-21
        javaPackages.compiler.temurin-bin.jre-17
        javaPackages.compiler.temurin-bin.jre-11
        javaPackages.compiler.temurin-bin.jre-8
        graalvmPackages.graalvm-oracle_25
        graalvmPackages.graalvm-oracle_17
        nixpkgs-graalvm.graalvmPackages.graalvm-oracle_21
      ];
    })
    mangohud
    umu-launcher
    heroic
    (lutris.override {
      extraLibraries = pkgs: [
      ];
      extraPkgs = pkgs: [
        pkgs.winetricks
      ];
    })
  ];
}
