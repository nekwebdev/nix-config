{
  flake.nixosModules.userOj = {
    lib,
    config,
    ...
  }: let
    # Temporary bootstrap password hash for "changeme".
    bootstrapPasswordHash = "$y$j9T$0JuRKfvwr2c3q8t6Xwhq50$gtXn6SMWDBPocjip50.HzR/3KhImTPXZWY7QKtF9WwD";
  in {
    config = {
      # HM-first exception: users/groups are system-level declarations.
      users.users.oj = {
        isNormalUser = true;
        group = "oj";
        extraGroups =
          ["wheel"]
          ++ lib.optional config.services.greetd.enable "greeter"
          ++ lib.optional config.networking.networkmanager.enable "networkmanager"
          ++ lib.optionals config.services.printing.enable [
            "lp"
            "lpadmin"
          ];
        # Applied only when the account is first created.
        initialHashedPassword = bootstrapPasswordHash;
      };

      users.groups.oj = {};
    };
  };
}
