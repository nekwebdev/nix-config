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

        # Do not let SSH-attached clients poison local panes with SSH_* from the attach env.
        set -g update-environment "DISPLAY WAYLAND_DISPLAY XAUTHORITY TERM TERM_PROGRAM"
        set-environment -gu SSH_CONNECTION
        set-environment -gu SSH_CLIENT
        set-environment -gu SSH_TTY
        set-environment -gF SSH_AUTH_SOCK "#{E:XDG_RUNTIME_DIR}/gcr/ssh"

        set -sg escape-time 0
        source-file -q "$HOME/.config/tmux/tmux.local.conf"
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
