{
  pkgs,
  inputs,
  ...
}:
let
  bind_vfio = pkgs.writeShellScript "bind_vfio.sh" ''
    ## Unbind gpu from nvidia and bind to vfio
    ${pkgs.supergfxctl}/bin/supergfxctl -m Vfio
    sleep 2
  '';

  unbind_vfio = pkgs.writeShellScript "unbind_vfio.sh" ''
    ## Unbind gpu from vfio and bind to nvidia
    ${pkgs.supergfxctl}/bin/supergfxctl -m NvidiaNoModeset
    sleep 2
  '';

in
{
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
      };
    };

  systemd.services.libvirtd = {
    preStart = ''
      mkdir -p /var/lib/libvirt/hooks
      mkdir -p /var/lib/libvirt/hooks/qemu.d/win10/prepare/begin
      mkdir -p /var/lib/libvirt/hooks/qemu.d/win10/release/end

      ln -sf ${bind_vfio} /var/lib/libvirt/hooks/qemu.d/win10/prepare/begin/bind_vfio.sh
      ln -sf ${unbind_vfio} /var/lib/libvirt/hooks/qemu.d/win10/release/end/unbind_vfio.sh
    '';
  };
}
