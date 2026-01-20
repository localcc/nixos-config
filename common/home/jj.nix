{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.jj;
in
{
  options = {
    jj = {
      enable = lib.mkEnableOption "Enable jj";
    };
  };

  config = lib.mkIf cfg.enable {

    programs.jujutsu = {
      enable = true;
      # package = pkgs.custom.jujutsu;

      settings = {
        user = {
          email = "work@localcc.cc";
          name = "Kate";
        };

        ui = {
          paginate = "never";
          # pager = "${pkgs.delta}/bin/delta";
          # for delta
          # diff-formatter = ":git";
          diff-formatter = [
            "${pkgs.difftastic}/bin/difft"
            "--color=always"
            "$left"
            "$right"
          ];

          default-command = [
            "log"
            "--reversed"
            "--no-pager"
          ];
          merge-editor = [
            "${pkgs.meld}/bin/meld"
            "$left"
            "$base"
            "$right"
            "-o"
            "$output"
            "--auto-merge"
          ];
          # diff-editor = "${pkgs.meld}/bin/meld";
        };

        fsmonitor.backend = "watchman";
        fsmonitor.watchman.register-snapshot-trigger = true;

        # revsets.log = "@ | ancestors(trunk()..(visible_heads() & mine()), 2) | trunk()";
        # revsets.log = "trunk()..@ | @..trunk() | trunk() | @:: | fork_point(trunk() | @)";
        revsets.log = "trunk() | ancestors(trunk()..heads(((trunk()..visible_heads()) & my() | @)::), 2)";

        revset-aliases = {
          "my()" = "user(\"${config.programs.jujutsu.settings.user.email}\")";
          "user(x)" = "author(x) | committer(x)";
          current = ''bookmarks() & my() & ~immutable()'';
          "closest_bookmark(to)" = "heads(::to & bookmarks())";
        };

        template-aliases = {
          "format_timestamp(timestamp)" = "timestamp.ago()";
          log_oneline = ''
            if(root,
              format_root_commit(self),
              label(if(current_working_copy, "working_copy"),
                concat(
                  separate(" ",
                    format_short_change_id_with_hidden_and_divergent_info(self),
                    if(empty, label("empty", "(empty)")),
                    if(description,
                      description.first_line(),
                      label(if(empty, "empty"), description_placeholder),
                    ),
                    bookmarks,
                    tags,
                    working_copies,
                    if(git_head, label("git_head", "HEAD")),
                    if(conflict, label("conflict", "conflict")),
                    if(config("ui.show-cryptographic-signatures").as_boolean(),
                      format_short_cryptographic_signature(signature)),
                  ) ++ "\n",
                ),
              )
            )
          '';
          status_summary = "'\n' ++ self.diff().summary() ++ '\n'";
          log_oneline_with_status_summary = "log_oneline ++ if(self.current_working_copy() && self.diff().files().len() > 0, status_summary)";
        };

        aliases =
          let
            util = script: [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              script
            ];
          in
          {
            tug = [
              "bookmark"
              "move"
              "--from"
              "heads(::@- & bookmarks())"
              "--to"
              "coalesce(@ & ~empty(), @-)"
            ];
            catchup = [
              "rebase"
              "-b"
              "bookmarks() & mine() & ~immutable()"
              "-d"
              "trunk()"
              "--skip-emptied"
            ];
            pull = util ''
              jj git fetch
              jj catchup
            '';
            ch = [
              "show"
              "--stat"
            ];
            move = [
              "rebase"
              "-r"
            ];
            push = [
              "git"
              "push"
            ];
            ll = [
              "log"
              "-T"
              "builtin_log_compact"
            ];
            mdiff = [
              "diff"
              "--from"
              "trunk()"
            ];
          };

        templates = {
          log_node = ''
            label("node",
              coalesce(
                if(!self, label("elided", "~")),
                if(current_working_copy, label("working_copy", "@")),
                if(conflict, label("conflict", "×")),
                if(immutable, label("immutable", "*")),
                label("normal", "·")
              )
            )
          '';
          log = "log_oneline_with_status_summary";
          git_push_bookmark = ''"kate/" ++ change_id.short()'';
        };

        signing = {
          # sign-all = true;
          behavior = "own";
          backend = "ssh";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHWfBIxvY4c0Rdava/cAEa3qGUOxMSt4Cu0Ap7RtSK7";
          backends.ssh.program = lib.getExe' pkgs._1password-gui "op-ssh-sign";
        };

        git = {
          private-commits = "description(glob:'wip:*') | description(glob:'trial:*')";
          write-change-id-header = true;

          fetch = [
            "upstream"
            "origin"
          ];
          push = "origin";
          auto-local-bookmark = true;

          # sign only on push, prevents 1pw spamming
          sign-on-push = true;
        };
      };
    };
  };
}
