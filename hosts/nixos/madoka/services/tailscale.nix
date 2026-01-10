{
  inputs,
  config,
  ...
}:
{
  age.secrets.madoka-tailscale-key.file = (inputs.self + /secrets/madoka-tailscale-key.age);
  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets.madoka-tailscale-key.path;
    useRoutingFeatures = "server";
  };
}
