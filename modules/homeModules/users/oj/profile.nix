{self, ...}: {
  flake.homeModules.ojProfile = {
    pkgs,
    config,
    osConfig ? {},
    ...
  }: {
    imports = [
      self.homeModules.ojBase
    ];

    # Keep frequently edited personal settings here.
    programs.git.settings.user = {
      name = "nekwebdev";
      email = "nekwebdev@users.noreply.github.com";
      signingkey = "${config.home.homeDirectory}/.ssh/nixos-${osConfig.networking.hostName}";
    };

    # HM-first: user-scoped packages from the niri profile.
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
      pkgs.claude-code
      pkgs.codex
      pkgs.mpv
    ];

    my.home.flatpak.apps = [
      "com.stremio.Stremio"
    ];

    # HM-first: user-scoped session variables from the niri profile.
    home.sessionVariables = {
      CODEX_HOME = "${config.home.homeDirectory}/.config/codex";
      TERMINAL = "ghostty";
    };
  };
}
