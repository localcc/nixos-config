{
  inputs,
  config,
  ...
}:
{
  age.secrets.madoka-tailscale-key.file = (inputs.secrets + /madoka-tailscale-key.age);
  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets.madoka-tailscale-key.path;
    useRoutingFeatures = "server";
  };
}
