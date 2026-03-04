{
  flake.nixosModules.system = {
    # HM-first exception: global Nix daemon settings are system-level.
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
