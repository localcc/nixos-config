let
  kate = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHWfBIxvY4c0Rdava/cAEa3qGUOxMSt4Cu0Ap7RtSK7";
  marble = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdCGPkULDG7fm5DtRjwcCxGuVlhSClIiBAQG6xM1YOf";

  hosts = [
    marble
  ];

  all = [ kate ] ++ hosts;
in
{
  "kate-password.age".publicKeys = all;

  # wifi
  "wifi-home.age".publicKeys = all;
}
