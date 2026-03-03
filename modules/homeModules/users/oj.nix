{self, ...}: {
  flake.homeModules.userOj = {
    config,
    lib,
    osConfig ? {},
    pkgs,
    wrappedPrograms,
    sopsUserSshKeyPath ? null,
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";
  in {
    imports =
      [
        self.homeModules.environment
        self.homeModules.fishEnv
        self.homeModules.aliasRegistry
        self.homeModules.aliasesCommon
      ]
      ++ lib.optionals isLotus [
        self.homeModules.bat
        self.homeModules.brave
        self.homeModules.eza
        self.homeModules.fastfetch
        self.homeModules.fzf
        self.homeModules.ghostty
        self.homeModules.mangohud
        self.homeModules.nixMonitor
        self.homeModules.niri
        self.homeModules.dms
        self.homeModules.starship
        self.homeModules.tlrc
        self.homeModules.vscode
        self.homeModules.zedEditor
        self.homeModules.zoxide
      ];

    assertions = [
      {
        assertion = sopsUserSshKeyPath != null;
        message = "homeModules.userOj requires `home-manager.extraSpecialArgs.sopsUserSshKeyPath` to match the SOPS user key.";
      }
    ];

    home.stateVersion = "25.11";
    programs.home-manager.enable = true;

    # HM-first: user-scoped packages and session variables from legacy lotus config.
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

    home.sessionVariables = lib.mkIf isLotus {
      CODEX_HOME = "${config.home.homeDirectory}/.config/codex";
      TERMINAL = "ghostty";
    };

    gtk = lib.mkIf isLotus {
      enable = true;
      theme = {
        name = "adw-gtk3";
        package = pkgs.adw-gtk3;
      };
    };

    xdg.configFile."gtk-4.0/gtk.css".source = lib.mkIf isLotus (
      pkgs.writeText "gtk-4.0-gtk.css" ''
        @import url("dank-colors.css");
      ''
    );

    home.pointerCursor = lib.mkIf isLotus {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 14;
      x11 = {
        enable = true;
        defaultCursor = "Adwaita";
      };
    };

    programs.git = {
      enable = true;
      package = wrappedPrograms.git;
      settings = {
        user = {
          name = "nekwebdev";
          email = "nekwebdev@users.noreply.github.com";
          signingkey = sopsUserSshKeyPath;
        };
        init.defaultBranch = "main";
        gpg.format = "ssh";
        commit.gpgSign = true;
        core.pager = "diff-so-fancy | less --tabs=4 -RFX";
        interactive.diffFilter = "diff-so-fancy --patch";
      };
    };
  };
}
