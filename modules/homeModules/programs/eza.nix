{...}: {
  flake.homeModules.eza = {
    config,
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";

    ezaAliases = {
      ls = "${pkgs.eza}/bin/eza -la --icons --color=always --group-directories-first";
      ll = "${pkgs.eza}/bin/eza -lag --icons --color=always --group-directories-first --octal-permissions";
      lg = "${pkgs.eza}/bin/eza -la --icons --color=always --group-directories-first --octal-permissions --no-time --no-filesize --no-permissions --no-user --git";
      lt = "${pkgs.eza}/bin/eza --tree --color=always";
    };
  in {
    config = lib.mkIf isLotus {
      programs.eza = {
        enable = true;
        enableBashIntegration = config.programs.bash.enable;
        enableFishIntegration = config.programs.fish.enable;
        enableZshIntegration = config.programs.zsh.enable;
        extraOptions = [
          "--color=always"
          "--group-directories-first"
          "--header"
          "--time-style=long-iso"
        ];
        git = true;
        icons = "auto";
      };

      my.home.aliases.fragments = [
        {
          source = "homeModules.programs.eza";
          aliases = ezaAliases;
        }
      ];
    };
  };
}
