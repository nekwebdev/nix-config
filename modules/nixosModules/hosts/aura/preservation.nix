{
  flake.nixosModules.hostAuraPreservation = {...}: {
    # HM-first exception: preservation controls system-level mount and tmpfiles policy.
    preservation = {
      enable = true;
      preserveAt."/persistent" = {
        commonMountOptions = [
          "x-gvfs-hide"
          "x-gdu.hide"
        ];

        directories = [
          "/etc/NetworkManager/system-connections"
          "/var/lib/AccountsService"
          "/var/lib/NetworkManager"
          "/var/lib/bluetooth"
          "/var/lib/flatpak"
          "/var/lib/fprint"
          "/var/lib/fwupd"
          "/var/lib/power-profiles-daemon"
          "/var/lib/systemd/coredump"
          "/var/lib/systemd/rfkill"
          "/var/lib/systemd/timers"
          "/var/lib/tailscale"
          "/var/log"
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
        ];

        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
          {
            file = "/etc/ssh/ssh_host_ed25519_key";
            how = "symlink";
            configureParent = true;
          }
          {
            file = "/etc/ssh/ssh_host_ed25519_key.pub";
            how = "symlink";
            configureParent = true;
          }
        ];

        users = {
          oj = {
            commonMountOptions = [
              "x-gvfs-hide"
              "x-gdu.hide"
            ];
            directories = [
              {
                directory = ".ssh";
                mode = "0700";
              }
              ".cache/nix"
              ".config/BraveSoftware"
              ".config/DankMaterialShell"
              ".config/codex"
              ".config/gh"
              ".config/niri"
              ".config/nixos"
              ".config/obsidian"
              ".config/ovpn"
              ".config/zed"
              ".gnupg"
              ".local/share/Steam"
              ".local/share/direnv"
              ".local/share/fish"
              ".local/share/keyrings"
              ".local/state/home-manager"
              ".local/state/nix"
              ".local/state/wireplumber"
              ".mozilla"
              ".steam"
              ".var/app"
              ".zen"
              "Desktop"
              "Documents"
              "Downloads"
              "Games"
              "Music"
              "Pictures"
              "Projects"
              "Videos"
            ];
            files = [
              ".bash_history"
            ];
          };

          root = {
            home = "/root";
            directories = [
              {
                directory = ".ssh";
                mode = "0700";
              }
            ];
          };
        };
      };
    };

    # The machine-id is bind-mounted from persistent storage in initrd.
    systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];

    # Preservation requires systemd initrd.
    boot.initrd.systemd.enable = true;

    # Keep volatile root from accumulating large temporary data.
    fileSystems."/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=8G"
        "mode=1777"
      ];
    };
  };
}
