{
  flake.nixosModules.system = {
    # HM-first exception: global Nix daemon settings are system-level.
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # HM-first exception: AppImage binfmt registration is system-level kernel/runtime plumbing.
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
