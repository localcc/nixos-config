{
  inputs,
  config,
  osConfig,
  ...
}:
{
  imports = [
    inputs.agenix.homeManagerModules.default
  ];

  age.identityPaths = [
    osConfig.age.secrets."xmachine-${config.home.username}".path
  ];
}
