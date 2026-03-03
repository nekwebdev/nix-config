{...}: {
  flake.homeModules.starship = {
    config,
    lib,
    osConfig ? {},
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";
  in {
    config = lib.mkIf isLotus {
      programs.starship = {
        enable = true;
        enableBashIntegration = config.programs.bash.enable;
        enableFishIntegration = config.programs.fish.enable;
        enableZshIntegration = config.programs.zsh.enable;
        configPath = "~/.config/starship/starship.toml";
      };
    };
  };
}
