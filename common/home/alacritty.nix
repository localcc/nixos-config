{
  pkgs,
  ...
}:
{
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    settings = {
      # window.decorations = "None";
      scrolling.history = 100000;

      # Gogh - Ayaka theme
      # colors = {
      #   primary = {
      #     foreground = "#cedaeb";
      #     background = "#36283d";
      #   };
      #   cursor = {
      #     cursor = "#cedaeb";
      #   };
      #   normal = {
      #     black = "#36283d";
      #     red = "#71ADE9";
      #     green = "#AB8CAE";
      #     yellow = "#9EA0D3";
      #     blue = "#8BB8E9";
      #     magenta = "#E1B4CE";
      #     cyan = "#cedaeb";
      #     white = "#9098a4";
      #   };
      #   bright = {
      #     black = "#71ADE9";
      #     red = "#AB8CAE";
      #     green = "#E59DB1";
      #     yellow = "#9EA0D3";
      #     blue = "#8BB8E9";
      #     magenta = "#E1B4CE";
      #     cyan = "#cedaeb";
      #     white = "#FFFEFE";
      #   };
      # };
    };
  };
}
