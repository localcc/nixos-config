{
  inputs,
  config,
  pkgs,
  lib,
  hostList,
  ...
}:
let
  nixosHosts = map (h: h.host) (lib.filter (h: h.system == "nixos") hostList);
in
{
  imports = [
    inputs.harmonia.nixosModules.harmonia
  ];

  age.secrets.madoka-harmonia-secret.file = (inputs.secrets + /madoka-harmonia-secret.age);
  age.secrets.madoka-cache-fetcher-ssh.file = (inputs.secrets + /madoka-cache-fetcher-ssh.age);
  age.secrets.madoka-cache-fetcher-ntfy.file = (inputs.secrets + /madoka-cache-fetcher-ntfy.age);

  services.harmonia-dev.cache = {
    enable = true;
    signKeyPaths = [ config.age.secrets.madoka-harmonia-secret.path ];
    settings = {
      bind = "[::1]:5001";
    };
  };

  services.caddy = {
    enable = true;
    extraConfig = ''      
      :5000 {
        handle_path /update-revs/* {
          root /var/lib/nix-auto-build/revs
          file_server
        }
      
        reverse_proxy [::1]:5001
      }
    '';
  };

  systemd.services.nix-auto-build = {
    description = "Update and build the nix config";
    path = with pkgs; [
      git
      nix
      openssh
      jq
      curl
    ];
    script = ''
      NTFY_KEY=$(cat ${config.age.secrets.madoka-cache-fetcher-ntfy.path})

      cd /var/lib/nix-auto-build
      rm -rf nixos-config || true

      git -c core.sshCommand="ssh -i ${config.age.secrets.madoka-cache-fetcher-ssh.path}" clone https://github.com/localcc/nixos-config.git
      cd nixos-config

      export GIT_SSH_COMMAND="ssh -i ${config.age.secrets.madoka-cache-fetcher-ssh.path}"
      nix flake update nixpkgs

      NIXPKGS_NODE=$(jq -r .nodes.root.inputs.nixpkgs flake.lock)
      COMMIT_ID=$(jq -r .nodes.$NIXPKGS_NODE.locked.rev flake.lock)

      for host in ${(lib.strings.concatStringsSep " " nixosHosts)}; do
        echo "Building $host..."
        if nix build .#nixosConfigurations.$host.config.system.build.toplevel \
          --out-link "/var/lib/nix-auto-build/result-$host" \
          --print-out-paths \
          --cores 4
        then
            echo "$COMMIT_ID" > "/var/lib/nix-auto-build/revs/nixpkgs-$host.rev"
        else
            curl -d "$host build failed" https://ntfy.sh/$NTFY_KEY
            echo "Warning: $host build failed, continuing..."
        fi
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      # blender/etc.
      TimeoutStartSec = "8h";
    };
  };

  systemd.timers.nix-auto-build = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # Ensure build directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/nix-auto-build 0755 root root -"
    "d /var/lib/nix-auto-build/revs  0777 root root -"
  ];
}
