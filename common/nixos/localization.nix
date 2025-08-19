{
  lib, ...
}:
{
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "uk";
  services.xserver.xkb.layout = "us";

  # timezone
  services.automatic-timezoned.enable = true;
  services.geoclue2.enableDemoAgent = lib.mkForce true;
  services.geoclue2.geoProviderUrl = "https://beacondb.net/v1/geolocate";
}
