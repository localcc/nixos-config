{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    inputs.ddns-client.nixosModules.default
  ];

  age.secrets.madoka-ddns-client.file = (inputs.secrets + /madoka-ddns-client.age);

  services.ddns-client = {
    enable = true;
    package = inputs.ddns-client.packages.${pkgs.stdenv.system}.default;
    configFile = config.age.secrets.madoka-ddns-client.path;
  };
}
