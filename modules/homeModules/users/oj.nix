{self, ...}: {
  flake.homeModules.userOj = {
    lib,
    osConfig ? {},
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";
  in {
    imports =
      [
        self.homeModules.userOjBase
        self.homeModules.userOjGit
        self.homeModules.userOjLotusPackages
        self.homeModules.userOjLotusSession
        self.homeModules.userOjLotusAppearance

        self.homeModules.environment
        self.homeModules.fishEnv
        self.homeModules.aliasRegistry
        self.homeModules.aliasesCommon
      ]
      ++ lib.optionals isLotus [
        self.homeModules.bat
        self.homeModules.brave
        self.homeModules.eza
        self.homeModules.fastfetch
        self.homeModules.fzf
        self.homeModules.ghostty
        self.homeModules.mangohud
        self.homeModules.nixMonitor
        self.homeModules.niri
        self.homeModules.dms
        self.homeModules.starship
        self.homeModules.tlrc
        self.homeModules.vscode
        self.homeModules.zedEditor
        self.homeModules.zoxide
      ];
  };
}
