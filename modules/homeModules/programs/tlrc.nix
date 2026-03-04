{...}: {
  flake.homeModules.tlrc = {pkgs, ...}: {
    home.packages = [pkgs.tlrc];

    services.tldr-update = {
      enable = true;
      package = pkgs.tlrc;
    };
  };
}
