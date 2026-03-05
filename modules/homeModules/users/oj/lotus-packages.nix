{...}: {
  flake.homeModules.userOjLotusPackages = {pkgs, ...}: {
    # HM-first: user-scoped packages from legacy lotus config.
    home.packages = [
      pkgs.discord
      pkgs.fira-code
      pkgs.fira-code-symbols
      pkgs.nautilus
      pkgs.nerd-fonts.fira-code
      pkgs.openvpn
      pkgs.protonup-qt
      pkgs.codex
      pkgs.mpv
    ];
  };
}
