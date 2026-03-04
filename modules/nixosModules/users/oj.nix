{
  flake.nixosModules.userOj = {
    lib,
    config,
    ...
  }: let
    usersSecretFile = ../../../secrets/users.yaml;
    hasUsersSecretFile = builtins.pathExists usersSecretFile;
    # Keep aligned with secrets/recipients/users/oj.txt expected key path.
    sopsAgeKeyFile = "/home/oj/.config/sops/age/keys.txt";
  in {
    config = lib.mkMerge [
      {
        # HM-first exception: users/groups are system-level declarations.
        users.users.oj = {
          isNormalUser = true;
          group = "oj";
          extraGroups = ["wheel"] ++ lib.optional config.networking.networkmanager.enable "networkmanager";
        };

        users.groups.oj = {};

        # HM-first exception: SOPS decryption key location is host-level secret plumbing.
        sops.age.keyFile = sopsAgeKeyFile;
      }

      (lib.mkIf hasUsersSecretFile {
        sops.secrets."users/oj-password" = {
          sopsFile = usersSecretFile;
          neededForUsers = true;
        };

        users.users.oj.hashedPasswordFile = config.sops.secrets."users/oj-password".path;
      })

      (lib.mkIf (!hasUsersSecretFile) {
        warnings = [
          "sops password secret missing at ${toString usersSecretFile}; keeping current password for user oj"
        ];
      })
    ];
  };
}
