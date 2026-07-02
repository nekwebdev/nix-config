{self, ...}: {
  flake.homeModules.ojLotusProfile = {
    config,
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    userContract = lib.attrByPath ["my" "users" config.home.username] null osConfig;
    gitIdentity =
      if userContract == null
      then {}
      else {
        name = userContract.githubUsername;
        email = userContract.email;
        signingkey = "${config.home.homeDirectory}/.ssh/nixos-${osConfig.networking.hostName}";
      };
  in {
    imports = [
      self.homeModules.ojBase
    ];

    assertions = [
      {
        assertion = userContract != null;
        message = "Expected osConfig.my.users.${config.home.username} to be defined by the matching NixOS user module.";
      }
    ];

    # Keep frequently edited personal settings here.
    programs.git.settings.user = gitIdentity;

    # HM-first: user-scoped packages.
    home.packages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.monsters-and-memories-launcher
      pkgs.openvpn
      self.packages.${pkgs.stdenv.hostPlatform.system}.orca-slicer
    ];

    # HM-first: user-scoped session variables.
    home.sessionVariables = {
      TERMINAL = "ghostty";
    };
  };
}
