{inputs, ...}: {
  flake.nixosModules.dmsGreeter = {lib, ...}: {
    imports = [inputs.dms.nixosModules.greeter];

    # HM-first exception: display manager and greeter are privileged system services.
    services.displayManager = {
      gdm.enable = lib.mkDefault false;
      defaultSession = lib.mkDefault "niri";
    };

    # HM-first exception: greeter wiring is host login/session plumbing.
    programs.dank-material-shell.greeter = {
      enable = true;
      compositor.name = "niri";
    };

    # HM-first exception: PAM/keyring policy is system authentication plumbing.
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
