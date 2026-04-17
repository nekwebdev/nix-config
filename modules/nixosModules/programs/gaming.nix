{
  flake.nixosModules.gaming = {pkgs, ...}: {
    # HM-first exception: ntsync is a kernel module for host-level runtime integration.
    boot.kernelModules = ["ntsync"];

    # HM-first exception: Steam setup touches multiarch/runtime host integration.
    programs.steam = {
      enable = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
    };

    # HM-first exception: gamemode is a privileged system service.
    programs.gamemode.enable = true;
  };
}
