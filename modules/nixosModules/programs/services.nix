{
  flake.nixosModules.services = {pkgs, ...}: {
    # HM-first exception: audio daemon and compatibility layers are privileged system services.
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
    };

    # HM-first exception: PulseAudio service toggle is part of host audio plumbing.
    services.pulseaudio.enable = false;

    # HM-first exception: realtime scheduling is system-level capability control.
    security.rtkit.enable = true;

    # HM-first exception: Bluetooth device management is kernel/hardware host plumbing.
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    # HM-first exception: locale categories are host-level C locale environment defaults.
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    # HM-first exception: console configuration is system tty behavior.
    console.useXkbConfig = true;
    console.font = "Lat2-Terminus16";

    # HM-first exception: compressed swap is host memory management.
    zramSwap.enable = true;

    # HM-first exception: these are privileged system services.
    services.power-profiles-daemon.enable = true;
    services.accounts-daemon.enable = true;
    services.gvfs.enable = true;

    # HM-first exception: printer daemon/drivers are privileged system services.
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        canon-capt
      ];
    };
  };
}
