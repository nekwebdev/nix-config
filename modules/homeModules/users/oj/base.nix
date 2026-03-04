{...}: {
  flake.homeModules.userOjBase = {
    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
}
