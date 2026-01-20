{
  ...
}:
{
  # colmena
  deployment = {
    targetHost = "192.168.0.53";
    # targetHost = "100.93.38.121";
    targetPort = 22;
    replaceUnknownProfiles = false;
    buildOnTarget = false;
    tags = [ "rei" "eva" ];
    targetUser = "kate";
  };

}
