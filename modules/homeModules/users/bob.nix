{self, ...}: {
  flake.homeModules.userBob = {
    imports = [
      self.homeModules.environment
      self.homeModules.fishEnv
      self.homeModules.aliasRegistry
      self.homeModules.aliasesCommon
    ];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
}
