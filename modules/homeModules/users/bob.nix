{self, ...}: {
  flake.homeModules.userBob = {
    imports = [self.homeModules.fishEnv];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
}
