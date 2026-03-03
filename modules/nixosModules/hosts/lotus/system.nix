{
  flake.nixosModules.hostLotusSystem = {lib, ...}: {
    # HM-first exception: global Nix daemon settings are system-level.
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # HM-first exception: locale/timezone define host identity.
    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "Pacific/Tahiti";

    # HM-first exception: resolver behavior is host networking plumbing.
    services.resolved.enable = lib.mkForce false;

    system.stateVersion = "25.11";
  };
}
