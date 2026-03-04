{self, ...}: {
  flake.homeModules.userBob = {
    imports = [
      self.homeModules.base
      self.homeModules.environment
      self.homeModules.fish
      self.homeModules.aliasRegistry
      self.homeModules.aliasesCommon
    ];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
}
