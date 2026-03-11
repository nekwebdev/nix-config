{self, ...}: {
  flake.homeModules.ojNiri = {
    pkgs,
    config,
    osConfig ? {},
    ...
  }: {
    imports = [
      self.homeModules.base
      self.homeModules.environment
      self.homeModules.fish
      self.homeModules.aliasRegistry
      self.homeModules.aliasesCommon
      self.homeModules.git
      self.homeModules.bat
      self.homeModules.brave
      self.homeModules.eza
      self.homeModules.fastfetch
      self.homeModules.fzf
      self.homeModules.ghostty
      self.homeModules.mangohud
      self.homeModules.nixMonitor
      self.homeModules.starship
      self.homeModules.tlrc
      self.homeModules.vscode
      self.homeModules.zedEditor
      self.homeModules.zoxide
      self.homeModules.niri
      self.homeModules.dms
    ];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;

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
      pkgs.openvpn
      pkgs.protonup-qt
      pkgs.faugus-launcher
      pkgs.codex
      pkgs.mpv
    ];

    # HM-first: user-scoped session variables from the niri profile.
    home.sessionVariables = {
      CODEX_HOME = "${config.home.homeDirectory}/.config/codex";
      TERMINAL = "ghostty";
      DOCKER_HOST = "unix:///run/user/${toString osConfig.users.users.${config.home.username}.uid}/docker.sock";
    };

    gtk = {
      enable = true;
      theme = {
        name = "adw-gtk3";
        package = pkgs.adw-gtk3;
      };
    };

    xdg.configFile."gtk-4.0/gtk.css" = {
      source = pkgs.writeText "gtk-4.0-gtk.css" ''
        @import url("dank-colors.css");
      '';
    };

    home.pointerCursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 14;
      x11 = {
        enable = true;
        defaultCursor = "Adwaita";
      };
    };
  };
}
