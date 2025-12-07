{
  pkgs,
  inputs,
  config,
  ...
}:
let
  nixvirt = inputs.NixVirt;
in
{
  imports = [ inputs.NixVirt.nixosModules.default ];

  boot.extraModulePackages = [ config.boot.kernelPackages.kvmfr ];
  boot.kernelModules = [ "kvmfr" ];
  boot.extraModprobeConfig = ''
    options kvmfr static_size_mb=128
  '';

  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", GROUP="kvm", MODE="0660"
  '';

  environment.systemPackages = with pkgs; [
    looking-glass-client
  ];

  virtualisation.libvirt = {
    enable = true;
    swtpm.enable = true;
    connections."qemu:///session" = {
      networks = [
        {
          definition = nixvirt.lib.network.writeXML {
            name = "nat0";
            uuid = "fc53e9f7-f190-4365-a78d-e1cd74b2e01b";
            forward = {
              mode = "nat";
              nat = {
                port.start = 1024;
                port.end = 65535;
              };
            };
            bridge = {
              name = "virbr0";
              stp = true;
              delay = 0;
            };
            ip = {
              address = "192.168.100.1";
              netmask = "255.255.255.0";
              dhcp = {
                range.start = "192.168.100.128";
                range.end = "192.168.100.254";
              };
            };
          };
          active = true;
          restart = null;
        }
      ];
    };
  };

  virtualisation.libvirtd =
    with pkgs;
    let
      unstable = import inputs.nixpkgs-unstable { inherit system; };
    in
    {
      package = unstable.libvirt;
      enable = true;
      qemu = {
        package = unstable.qemu;
        swtpm.enable = true;
        verbatimConfig = ''
          cgroup_device_acl = [
              "/dev/null", "/dev/full", "/dev/zero",
              "/dev/random", "/dev/urandom",
              "/dev/ptmx", "/dev/kvm",
              "/dev/userfaultfd", "/dev/kvmfr0"
          ]
        '';
      };
    };
}
