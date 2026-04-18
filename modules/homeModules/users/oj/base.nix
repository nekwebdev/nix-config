{self, ...}: {
  flake.homeModules.ojBase = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      self.homeModules.base
      self.homeModules.environment
      self.homeModules.fish
      self.homeModules.aliasRegistry
      self.homeModules.aliasesCommon
      self.homeModules.git
      self.homeModules.assistants
      self.homeModules.bat
      self.homeModules.brave
      self.homeModules.eza
      self.homeModules.fastfetch
      self.homeModules.fzf
      self.homeModules.ghostty
      self.homeModules.mangohud
      self.homeModules.nixMonitor
      self.homeModules.obsidian
      self.homeModules.starship
      self.homeModules.tmux
      self.homeModules.tlrc
      self.homeModules.vscode
      self.homeModules.zedEditor
      self.homeModules.zoxide
      self.homeModules.niri
      self.homeModules.dms
    ];

    options.my.home.flatpak.apps = lib.mkOption {
      default = [];
      description = "Flatpak app IDs requested by this user profile.";
      type = lib.types.listOf lib.types.str;
    };

    config = {
      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3";
          package = pkgs.adw-gtk3;
        };
        gtk4.theme = config.gtk.theme;
        gtk4.extraCss = ''
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

      home.stateVersion = "25.11";
      programs.home-manager.enable = true;
    };
  };
}
