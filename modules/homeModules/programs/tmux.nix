{
  flake.homeModules.tmux = {pkgs, ...}: {
    programs.tmux = {
      enable = true;
      package = pkgs.tmux;

      # Match the existing shell setup when opening new tmux panes/windows.
      shell = "${pkgs.fish}/bin/fish";
      terminal = "screen-256color";
      sensibleOnTop = true;
      mouse = true;
    };
  };
}
