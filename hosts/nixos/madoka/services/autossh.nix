{
  inputs,
  config,
  lib,
  ...
}:
let
  pfPorts = [
    5000
  ];

  pfArgs = map (p: "-R 0.0.0.0:${(toString p)}:127.0.0.1:${(toString p)}") pfPorts;
in

{
  age.secrets.madoka-autossh = {
    file = (inputs.secrets + /madoka-autossh.age);
    owner = "kate";
    mode = "600";
  };

  services.autossh-ng.sessions = {
    pf-portfwd = {
      destination = "kate@cache.madoka.dev";
      extraArguments = lib.strings.concatStringsSep " " (
        pfArgs ++ [ "-i ${config.age.secrets.madoka-autossh.path}" ]
      );
      user = "kate";
      hostKeyChecking = false; # TODO: kate fix this
    };
  };
}
