{...}: {
  flake.homeModules.obsidian = {pkgs, ...}: {
    # HM-first: Obsidian is a user-scoped desktop application.
    programs.obsidian = {
      enable = true;
      package = pkgs.obsidian;
    };
  };
}
