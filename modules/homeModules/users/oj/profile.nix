{self, ...}: {
  flake.homeModules.ojProfile = {
    pkgs,
    lib,
    config,
    osConfig ? {},
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
      pkgs.discord
      pkgs.fira-code
      pkgs.fira-code-symbols
      self.packages.${pkgs.stdenv.hostPlatform.system}.monsters-and-memories-launcher
      pkgs.nautilus
      pkgs.nerd-fonts.fira-code
      pkgs.nodejs
      pkgs.openvpn
      self.packages.${pkgs.stdenv.hostPlatform.system}.orca-slicer
      self.packages.${pkgs.stdenv.hostPlatform.system}.pinokio
      pkgs.protonup-qt
      pkgs.faugus-launcher
      pkgs.mpv
    ];

    my.home.flatpak.apps = [
      "com.stremio.Stremio"
    ];

    # HM-first: user-scoped session variables.
    home.sessionVariables = {
      TERMINAL = "ghostty";
    };
  };
}
