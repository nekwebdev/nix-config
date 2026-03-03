{
  flake.nixosModules.base = {
    # HM-first exception: sudo policy is system-level.
    security.sudo.enable = true;
  };
}
