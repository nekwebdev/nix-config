{
  flake.homeModules.fish = {pkgs, ...}: {
    programs.fish = {
      enable = true;
      package = pkgs.fish;

      # Preserve legacy done-plugin behavior.
      interactiveShellInit = ''
        set fish_greeting

        if not set -q __done_min_cmd_duration
          set -U __done_min_cmd_duration 10000
        end

        set reminder_file "$HOME/.local/state/nix/password-bootstrap-reminder"
        if test -f $reminder_file
          echo "[nixos] Bootstrap password reminder: run 'passwd' to set your password, then open a new shell."
        end
      '';

      plugins = [
        {
          name = "done";
          src = pkgs.fishPlugins.done.src;
        }
        {
          name = "bang-bang";
          src = pkgs.fishPlugins.bang-bang.src;
        }
      ];

      functions = {
        history.body = ''
          builtin history --show-time='%F %T ' $argv
        '';

        backup.body = ''
          if test (count $argv) -ne 1
            echo "Usage: backup <filename>"
            return 1
          end

          cp $argv[1] $argv[1].bak
        '';

        passwd.body = ''
          command passwd $argv
          set passwd_status $status

          if test $passwd_status -eq 0
            set state_dir "$HOME/.local/state/nix"
            set reminder_file "$state_dir/password-bootstrap-reminder"
            set ack_file "$state_dir/password-bootstrap-ack"

            mkdir -p $state_dir
            touch $ack_file
            rm -f $reminder_file
          end

          return $passwd_status
        '';

        pi.body = ''
          set -l pi_bin "$HOME/.local/bin/pi"
          set -l pi_lens_dir "$HOME/.pi/pi-lens"

          if not test -x "$pi_bin"
            echo "pi not found at path: $pi_bin" >&2
            return 1
          end

          if not test -d "$pi_lens_dir"
            command mkdir -p "$pi_lens_dir"
          end

          set -lx PILENS_DATA_DIR "$pi_lens_dir"

          command "$pi_bin" $argv
        '';

        pi-agents.body = ''
          set -l profile $argv[1]

          if test -z "$profile"
            echo "usage: pi-agents <profile> [pi args...]" >&2
            return 2
          end

          set -e argv[1]

          set -l pi_bin "$HOME/.local/bin/pi"
          set -l env_file "$HOME/pi-agents/$profile/.env.pi"

          if not test -x "$pi_bin"
            echo "pi not found at path: $pi_bin" >&2
            return 1
          end

          if not test -f "$env_file"
            echo ".env.pi not found at path: $env_file" >&2
            return 1
          end

          command bash -c 'set -a; source "$1"; set +a; shift; exec "$@"' bash "$env_file" "$pi_bin" $argv
        '';
      };
    };
  };
}
