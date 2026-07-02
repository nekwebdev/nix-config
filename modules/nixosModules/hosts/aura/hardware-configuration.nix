{
  flake.nixosModules.hostAuraHardware = {
    config,
    lib,
    modulesPath,
    pkgs,
    ...
  }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    # HM-first exception: hardware boot/initrd configuration is system-level.
    boot = {
      kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

      initrd = {
        availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod"];
        kernelModules = [];
      };

      kernelModules = ["kvm-intel"];
      extraModulePackages = [];
    };

    # HM-first exception: firmware, graphics, and CPU features are host hardware policy.
    hardware = {
      enableRedistributableFirmware = true;

      cpu.intel = {
        updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        npu.enable = true;
      };

      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    swapDevices = [];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
