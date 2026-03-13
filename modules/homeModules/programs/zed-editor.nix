{...}: {
  flake.homeModules.zedEditor = {
    config,
    pkgs,
    ...
  }: let
    repoRoot = ../../../.;
    settingsPath = "${repoRoot}/configs/users/${config.home.username}/common/zed/settings.json";
    repoSettings =
      if builtins.pathExists settingsPath
      then builtins.fromJSON (builtins.readFile settingsPath)
      else {};
  in {
    programs.zed-editor = {
      enable = true;
      mutableUserSettings = true;
      userSettings = repoSettings;
      extraPackages = with pkgs; [
        nil
        nixd
      ];
    };
  };
}
