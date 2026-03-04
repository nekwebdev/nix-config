{...}: {
  flake.homeModules.userOjLotusAppearance = {
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    isLotus = (osConfig.networking.hostName or null) == "lotus";
  in {
    gtk = lib.mkIf isLotus {
      enable = true;
      theme = {
        name = "adw-gtk3";
        package = pkgs.adw-gtk3;
      };
    };

    xdg.configFile."gtk-4.0/gtk.css" = lib.mkIf isLotus {
      source = pkgs.writeText "gtk-4.0-gtk.css" ''
        @import url("dank-colors.css");
      '';
    };

    home.pointerCursor = lib.mkIf isLotus {
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
