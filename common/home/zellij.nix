{
  pkgs,
  ...
}:
{
  programs.zellij = {
    enable = true;
    extraConfig = ''
      keybinds {
        unbind "Ctrl o"
        unbind "Ctrl s"
        normal {
          bind "Ctrl PageUp" { GoToPreviousTab; }
          bind "Ctrl PageDown" { GoToNextTab; }
          bind "Ctrl Shift t" { NewTab; }
          bind "Ctrl Shift w" { CloseTab; }
          bind "Ctrl Shift PageUp" { MoveTab "Left"; }
          bind "Ctrl Shift PageDown" { MoveTab "Right"; }
        }
      }
    '';
    layouts = {
      default = ''
        layout {
          pane size=1 borderless=true {
            plugin location="tab-bar"
          }
          pane
        }
      '';
      ai = ''
        layout {
          default_tab_template {
            pane size=1 borderless=true {
              plugin location="tab-bar"
            }
            children
          }
        
          tab name="Helix" {
            pane {
              command "nix"
              args "develop" "-c" "nu" "-c" "hx"
              close_on_exit true
            }
          }
          tab name="Terminal" {
            pane {
              command "nix"
              args "develop" "-c" "nu"
              close_on_exit true
            }
          }
          tab {
            pane {
              command "nix"
              args "develop" "-c" "nu" "-c" "opencode" "--auto"
              close_on_exit true
            }
          }
        }
      '';
    };
  };

  home.packages = [
    (pkgs.writeShellApplication {
      name = "zellai";
      runtimeInputs = [ pkgs.zellij ];
      text = ''
        zellij -l ai
      '';
    })
  ];
}
