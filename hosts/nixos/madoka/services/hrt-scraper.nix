{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.hrt-scraper.nixosModules.default
  ];

  age.secrets.madoka-hrt-scraper.file = (inputs.secrets + /madoka-hrt-scraper.age);

  services.hrt-scrapper = {
    enable = true;
    configFile = config.age.secrets.madoka-hrt-scraper.path;
  };
}
