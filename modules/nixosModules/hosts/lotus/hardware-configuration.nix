{
  flake.nixosModules.hostLotusHardware = {
    config,
    lib,
    modulesPath,
    ...
  }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    # HM-first exception: hardware boot/initrd configuration is system-level.
    boot = {
      initrd = {
        availableKernelModules = ["nvme" "xhci_pci" "ahci" "uas" "usb_storage" "usbhid" "sd_mod" "igb"];
        kernelModules = [];
        luks.devices."crypt-nix".device = "/dev/disk/by-uuid/bc131367-5e31-40ab-836d-2f4f335dfd63";
      };
      kernelModules = ["kvm-amd"];
      extraModulePackages = [];
    };

    # HM-first exception: filesystem layout/mounts are host-level hardware policy.
    fileSystems = {
      "/" = {
        device = "/dev/mapper/crypt-nix";
        fsType = "btrfs";
        options = ["subvol=@root"];
      };

      "/home" = {
        device = "/dev/mapper/crypt-nix";
        fsType = "btrfs";
        options = ["subvol=@home"];
      };

      "/nix" = {
        device = "/dev/mapper/crypt-nix";
        fsType = "btrfs";
        options = ["subvol=@nix"];
      };

      "/var/log" = {
        device = "/dev/mapper/crypt-nix";
        fsType = "btrfs";
        options = ["subvol=@log"];
      };

      "/var/cache" = {
        device = "/dev/mapper/crypt-nix";
        fsType = "btrfs";
        options = ["subvol=@cache"];
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/E807-A411";
        fsType = "vfat";
        options = ["fmask=0077" "dmask=0077"];
      };

      "/mnt/games" = {
        device = "/dev/disk/by-uuid/ee11d766-2077-4974-888e-c435ed1ec625";
        fsType = "btrfs";
        options = ["compress=zstd" "noatime"];
      };
    };

    swapDevices = [];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
