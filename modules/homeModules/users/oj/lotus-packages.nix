{...}: {
  flake.homeModules.userOjLotusPackages = {
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";
  in {
    # HM-first: user-scoped packages from legacy lotus config.
    home.packages = lib.mkIf isLotus [
      pkgs.discord
      pkgs.fira-code
      pkgs.fira-code-symbols
      pkgs.nautilus
      pkgs.nerd-fonts.fira-code
      pkgs.openvpn
      pkgs.protonup-qt
      pkgs.codex
    ];
  };
}
