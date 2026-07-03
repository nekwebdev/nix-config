{
  flake.nixosModules.gaming = {
    config,
    lib,
    pkgs,
    ...
  }: {
    # HM-first exception: ntsync is a kernel module for host-level runtime integration.
    boot.kernelModules = ["ntsync"];

    # HM-first exception: Steam setup touches multiarch/runtime host integration.
    programs.steam = {
      enable = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
      package = lib.mkIf (config.networking.hostName == "aura") (pkgs.steam.override {
        # Steam CEF renders a blank window on Aura's Lunar Lake Arc iGPU under niri/Wayland.
        extraArgs = "-cef-disable-gpu";
        extraEnv.NIXOS_OZONE_WL = "0";
      });
    };

    environment.systemPackages = [pkgs.protontricks];

    # HM-first exception: gamemode is a privileged system service.
    programs.gamemode.enable = true;
  };
}
