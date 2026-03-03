{
  flake.homeModules.userBob = {
    imports = [(import ../../../home/shell/fish-env.nix)];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
}
