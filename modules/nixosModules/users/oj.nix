{
  flake.nixosModules.userOj = {
    # HM-first exception: users/groups are system-level declarations.
    users.users.oj = {
      isNormalUser = true;
      group = "oj";
      extraGroups = ["wheel"];
    };

    users.groups.oj = {};
  };
}
