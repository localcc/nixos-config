{
  ...
}:
{
  programs.zellij = {
    enable = true;
    extraConfig = ''
      keybinds {
        unbind "Ctrl o"
        normal {
          bind "Ctrl PageUp" { GoToPreviousTab; }
          bind "Ctrl PageDown" { GoToNextTab; }
          bind "Ctrl Shift t" { NewTab; }
          bind "Ctrl Shift w" { CloseTab; }
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
