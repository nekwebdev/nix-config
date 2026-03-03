{
  flake.nixosModules.userBob = {
    # HM-first exception: users/groups are system-level declarations.
    users.users.bob = {
      isNormalUser = true;
      group = "bob";
      extraGroups = ["wheel"];
    };

    users.groups.bob = {};
  };
}
