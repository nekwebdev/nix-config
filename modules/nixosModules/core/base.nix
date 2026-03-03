{
  flake.nixosModules.base = {
    # HM-first exception: bootloader configuration is system-level.
    boot.loader.grub.enable = true;
    boot.loader.grub.devices = ["nodev"];

    # HM-first exception: root filesystem declarations are system-level.
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
    };

    # HM-first exception: sudo policy is system-level.
    security.sudo.enable = true;
  };
}
