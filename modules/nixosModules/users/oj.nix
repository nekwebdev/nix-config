{
  flake.nixosModules.userOj = {
    lib,
    config,
    ...
  }: let
    # Temporary bootstrap password hash for "changeme".
    bootstrapPasswordHash = "$y$j9T$0JuRKfvwr2c3q8t6Xwhq50$gtXn6SMWDBPocjip50.HzR/3KhImTPXZWY7QKtF9WwD";
    user = config.my.users.oj;
  in {
    config = {
      my.users.oj = {
        githubUsername = "nekwebdev";
        email = "nekwebdev@users.noreply.github.com";
        isAdmin = true;
        extraGroups =
          ["wheel"]
          ++ lib.optional config.virtualisation.docker.enable "docker"
          ++ lib.optional config.virtualisation.libvirtd.enable "libvirtd"
          ++ lib.optional config.services.greetd.enable "greeter"
          ++ lib.optional config.networking.networkmanager.enable "networkmanager"
          ++ lib.optionals config.services.printing.enable [
            "lp"
            "lpadmin"
          ];
      };

      # HM-first exception: users/groups are system-level declarations.
      users.users.${user.username} = {
        isNormalUser = true;
        group = user.primaryGroup;
        home = lib.mkDefault user.homeDirectory;
        extraGroups = user.extraGroups;
        # Applied only when the account is first created.
        initialHashedPassword = bootstrapPasswordHash;
      };

      users.groups.${user.primaryGroup} = {};

      # HM-first exception: trusted users are a global daemon policy concern.
      nix.settings.trusted-users = lib.optionals user.isAdmin [user.username];
    };
  };
}
