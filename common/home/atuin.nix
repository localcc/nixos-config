{
  pkgs,
  lib,
  ...
}:
{
  programs.nushell = {
    enable = true;
    package = pkgs.nushell;
  };

  # atuin registers at 2000
  programs.nushell.extraConfig = lib.mkOrder 3000 ''
    # Orphaned-shell guard. When a terminal dies, its nu shells lose /dev/tty;
    # the REPL then free-runs and atuin's pre_prompt hook panics in `job spawn`
    # on every iteration (~1 core per orphan). `exit` is swallowed inside
    # hooks, so self-terminate with kill instead.
    $env.config.hooks.pre_prompt = (
      $env.config.hooks.pre_prompt? | default []
      | prepend {||
        if (try { "" | save --force /dev/tty; false } catch { true }) {
          kill -q --force $nu.pid
        }
      }
    )
  '';

  programs.atuin = {
    enable = true;
    settings = {
      auto_sync = false;
      enableNushellIntegration = true;
      search_mode = "fuzzy";
    };
  };
}
