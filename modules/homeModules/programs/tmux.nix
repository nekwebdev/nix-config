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

      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.resurrect;
          extraConfig = ''
            set -g @resurrect-dir '~/.local/state/tmux/resurrect'
            set -g @resurrect-capture-pane-contents 'on'
          '';
        }
        {
          plugin = tmuxPlugins.continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '15'
          '';
        }
      ];
    };
  };
}
