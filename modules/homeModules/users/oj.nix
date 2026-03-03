{self, ...}: {
  flake.homeModules.userOj = {
    imports = [
      self.homeModules.fishEnv
      self.homeModules.aliasRegistry
      self.homeModules.aliasesCommon
    ];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
}
