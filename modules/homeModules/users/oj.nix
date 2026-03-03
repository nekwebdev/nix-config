{self, ...}: {
  flake.homeModules.userOj = {
    imports = [self.homeModules.fishEnv];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
}
