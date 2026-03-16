{inputs, ...}: {
  flake.nixosModules.system = {lib, ...}: {
    # HM-first exception: global Nix daemon settings are system-level.
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # HM-first exception: package-set overlays are host-level composition plumbing.
    nixpkgs.overlays = lib.mkAfter [inputs.claude-code.overlays.default];

    # HM-first exception: AppImage binfmt registration is system-level kernel/runtime plumbing.
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
