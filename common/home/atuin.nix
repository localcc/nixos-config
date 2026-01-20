{
  pkgs,
  ...
}:
{
  programs.nushell = {
    enable = true;
    package = pkgs.nushell;
  };

  programs.atuin = {
    enable = true;
    settings = {
      auto_sync = false;
      enableNushellIntegration = true;
      search_mode = "fuzzy";
    };
  };
}
