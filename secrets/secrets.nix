let
  kate = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHWfBIxvY4c0Rdava/cAEa3qGUOxMSt4Cu0Ap7RtSK7";
  marble = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdCGPkULDG7fm5DtRjwcCxGuVlhSClIiBAQG6xM1YOf";
  madoka = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMovxmS1MRZItFdPufQtPp4FlpxNCGMYXlQBfK2uw3Il";

  hosts = [
    marble
    madoka
  ];

  desktop = [ kate ] ++ [
    marble
  ];
  server = [ kate ] ++ [
    madoka
  ];
  all = [ kate ] ++ hosts;
in
{
  "kate-password.age".publicKeys = all;
  "pfp.age".publicKeys = desktop;

  # wifi
  "wifi-home.age".publicKeys = desktop;

  # samba
  "smb-localcc-password.age".publicKeys = server;
  "smb-ambra-password.age".publicKeys = server;

  # tailscale
  "madoka-tailscale-key.age".publicKeys = [ kate madoka ];
}
