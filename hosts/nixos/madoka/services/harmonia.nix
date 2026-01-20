{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.harmonia.nixosModules.harmonia
  ];

  age.secrets.madoka-harmonia-secret.file = (inputs.secrets + /madoka-harmonia-secret.age);

  services.harmonia-dev.cache = {
    enable = true;
    signKeyPaths = [ config.age.secrets.madoka-harmonia-secret.path ];
  };
}
