{
  inputs, pkgs, config, ...
}:
{
  age.secrets.kate-password.file = (inputs.self + /secrets/kate-password.age);

  users.mutableUsers = false;
  users.users = {
    ${config.me.username} = {
      isNormalUser = true;
      uid = 1000;
      group = "users";
      extraGroups = [
        "wheel" # sudo
        "networkmanager" # network configuration
      ];

      shell = pkgs.nushell;
      hashedPasswordFile = config.age.secrets.kate-password.path;
      openssh.authorizedKeys.keys = config.me.sshKeys;
    };
  };

  users.groups.users.gid = 100;
}
