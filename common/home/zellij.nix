{
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
    };
  };
}
