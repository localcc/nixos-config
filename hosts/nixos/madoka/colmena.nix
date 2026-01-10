{
  ...
}:
{
  # colmena
  deployment = {
    targetHost = "192.168.0.16";
    targetPort = 22;
    replaceUnknownProfiles = false;
    buildOnTarget = false;
    tags = [ "nas" ];
    targetUser = "kate";
  };

}
