{...}: {
  flake.homeModules.userOjLotusAppearance = {pkgs, ...}: {
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
