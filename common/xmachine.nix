{
  inputs,
  lib,
  hostname,
  ...
}:
let
  xmachineKeys = {
    kate = {
      path = (inputs.secrets + /user-keys/kate-xmachine.age);
      machines = [
        "madoka"
        "marble"
        "cider"
      ];
    };
  };

  filteredKeys = lib.filterAttrs (
    name: value: lib.lists.elem hostname value.machines
  ) xmachineKeys;

  xmachineKeyAttrs = lib.mapAttrs' (name: value: {
    name = "xmachine-${name}";
    value = {
      file = value.path;
      owner = name;
      mode = "600";
    };
  }) filteredKeys;
in
{
  config.age.secrets = xmachineKeyAttrs;
}
