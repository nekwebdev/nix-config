{
  flake.nixosModules.portals = {pkgs, ...}: {
    # HM-first exception: portal providers are system-integrated desktop services.
    xdg.portal = {
      enable = true;
      config.common.default = "*";
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
    };
  };
}
