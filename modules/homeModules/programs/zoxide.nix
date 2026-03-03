{...}: {
  flake.homeModules.zoxide = {
    config,
    lib,
    osConfig ? {},
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";
  in {
    config = lib.mkIf isLotus {
      programs.zoxide = {
        enable = true;
        enableBashIntegration = config.programs.bash.enable;
        enableFishIntegration = config.programs.fish.enable;
        enableZshIntegration = config.programs.zsh.enable;
        options = ["--cmd cd"];
      };
    };
  };
}
