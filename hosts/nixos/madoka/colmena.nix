{
  ...
}:
{
  # colmena
  deployment = {
    targetHost = "192.168.0.56";
    targetPort = 22;
    replaceUnknownProfiles = false;
    buildOnTarget = false;
    tags = [ "nas" ];
    targetUser = "kate";
  };

}
