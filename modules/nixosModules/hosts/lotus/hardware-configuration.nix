{
  flake.nixosModules.hostLotus = {lib, ...}: {
    # HM-first exception: root and boot filesystems are host-level hardware.
    fileSystems."/" = {
      device = "/dev/mapper/crypt-nix";
      fsType = "btrfs";
      options = ["subvol=@root"];
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/E807-A411";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
