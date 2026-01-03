{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  sambaUsers = [
    {
      username = "localcc";
      password = "smb-localcc-password";
    }
    {
      username = "ambra";
      password = "smb-ambra-password";
    }
  ];

  systemUsers = map (user: {
    age.secrets."${user.password}".file = (inputs.self + /secrets/${user.password}.age);

    users.users.${user.username} = {
      isNormalUser = true;
      extraGroups = [ "samba" ];
      # this is actually a lie it's not a hash but i can deal with it later
      hashedPasswordFile = config.age.secrets.${user.password}.path;
    };
  }) sambaUsers;

  # dirty way to just print the password twice into stdin of smbpasswd
  # results in something like
  # echo "123\n123" | smbpasswd -sa username
  # to add the user to smb
  mkInitLine =
    user:
    let
      binDir = "/run/current-system/sw/bin";
      pwdPath = config.age.secrets.${user.password}.path;
    in
    ''${binDir}/printf "$(${binDir}/cat ${pwdPath})\n$(${binDir}/cat ${pwdPath})\n" | ${binDir}/smbpasswd -sa ${user.username}'';
  initScript = builtins.concatStringsSep "\n" (map (user: mkInitLine user) sambaUsers);
in
{
  # default dirs
  #systemd.tmpfiles.rules = [
  #  "d /mnt/Storage/WitchHut 1770 root users -"
  #  "d /mnt/Storage/WitchHut/Kate 1700 localcc root -"
  #];
  
  # Smb
  services.samba = {
    package = pkgs.samba4Full;
    enable = true;
    openFirewall = true;

    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "madoka";
        "netbios name" = "madoka";
        "security" = "user";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "smb encrypt" = "required";
      };
      "WitchHut" = {
        "path" = "/mnt/Storage/WitchHut";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "inherit acls" = "yes";
        "valid users" = "localcc,ambra";
        "force group" = "users";
      };
    };
  };

  # smb windows discovery
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.avahi = {
    publish.enable = true;
    publish.userServices = true;
    nssmdns4 = true;
    enable = true;
    openFirewall = true;
  };

  # creating all users
  system.activationScripts = {
    init_smbpasswd.text = initScript;
  };

  networking.firewall.allowPing = true;
}
// builtins.foldl' lib.recursiveUpdate { } systemUsers
