{...}: {
  flake.homeModules.starship = {config, ...}: {
    programs.starship = {
      enable = true;
      enableBashIntegration = config.programs.bash.enable;
      enableFishIntegration = config.programs.fish.enable;
      enableZshIntegration = config.programs.zsh.enable;
      configPath = "~/.config/starship/starship.toml";
    };
  };
}
