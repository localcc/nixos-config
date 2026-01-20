{
  ...
}:
{
  # colmena
  deployment = {
    targetHost = "cache.madoka.dev";
    # targetHost = "100.93.38.121";
    targetPort = 22;
    replaceUnknownProfiles = false;
    buildOnTarget = false;
    tags = [ "stapler" ];
    targetUser = "kate";
  };

}
