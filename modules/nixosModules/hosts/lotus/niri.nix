{inputs, ...}: {
  flake.nixosModules.hostLotusNiri = {
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.niri.nixosModules.niri];

    # HM-first exception: compositor session registration is host login/session plumbing.
    programs.niri.enable = true;

    # HM-first exception: this user service is owned by the system compositor module session policy.
    systemd.user.services.niri-flake-polkit.enable = false;

    # HM-first exception: compositor package pinning belongs to host-level session composition.
    nixpkgs.overlays = lib.mkAfter [inputs.niri.overlays.niri];
    programs.niri.package = pkgs.niri-unstable;

    # HM-first exception: this environment variable is required globally for host Wayland sessions.
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
