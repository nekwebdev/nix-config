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
      };
    };
  };
}
