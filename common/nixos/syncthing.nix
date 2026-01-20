{
  ...
}:
{
  blackwall.rules.syncthing = {
    from = [ "uplink" ];
    destinationPorts = [
      {
        port = 22000;
        type = "tcp";
      }
      {
        port = 22000;
        type = "udp";
      }
      {
        port = 21027;
        type = "udp";
      }
    ];
    verdict = "accept";
  };
}
