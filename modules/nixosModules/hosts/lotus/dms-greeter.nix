{inputs, ...}: {
  flake.nixosModules.hostLotusDmsGreeter = {lib, ...}: {
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
      configHome = "/home/oj";
    };

    # HM-first exception: PAM/keyring policy is system authentication plumbing.
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    security.pam.services.greetd.enableGnomeKeyring = true;

    # HM-first exception: greetd overrides are system config under /etc.
    environment.etc."greetd/niri_overrides.kdl".text = ''
      output "DP-2" {
        position x=0 y=0
        scale 1
      }

      output "DP-1" {
        position x=5120 y=0
        scale 1
      }
    '';
  };
}
