{
  flake.homeModules.tmux = {pkgs, ...}: {
    programs.tmux = {
      enable = true;
      package = pkgs.tmux;

      # Keep SHELL aligned with the account login shell while panes exec fish for interaction.
      shell = "${pkgs.bashInteractive}/bin/bash";
      terminal = "screen-256color";
      sensibleOnTop = true;
      mouse = true;
      extraConfig = ''
        set -g default-command "exec ${pkgs.fish}/bin/fish"
        set -g allow-passthrough on
        set -g extended-keys on
        set -g extended-keys-format csi-u
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM
        set -sg escape-time 0
      '';

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
