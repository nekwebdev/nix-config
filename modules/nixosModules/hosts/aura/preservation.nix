{
  flake.nixosModules.hostAuraPreservation = {lib, ...}: {
    # HM-first exception: preservation controls system-level mount and tmpfiles policy.
    preservation = {
      enable = true;
      preserveAt."/persistent" = {
        commonMountOptions = [
          "x-gvfs-hide"
          "x-gdu.hide"
        ];

        directories = [
          {
            directory = "/tmp";
            mode = "1777";
          }
          {
            directory = "/var/tmp";
            mode = "1777";
          }
          "/etc/NetworkManager/system-connections"
          "/var/lib/AccountsService"
          "/var/cache/fwupd"
          "/var/cache/fwupdmgr"
          "/var/lib/cups"
          "/var/lib/NetworkManager"
          "/var/lib/bluetooth"
          "/var/lib/flatpak"
          "/var/lib/fprint"
          "/var/lib/fwupd"
          {
            directory = "/var/lib/dms-greeter";
            user = "greeter";
            group = "greeter";
            mode = "0750";
          }
          "/var/lib/power-profiles-daemon"
          "/var/lib/upower"
          "/var/lib/systemd/backlight"
          "/var/lib/systemd/coredump"
          "/var/lib/systemd/rfkill"
          "/var/lib/systemd/timers"
          "/var/lib/tailscale"
          "/var/lib/udisks2"
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
          "/var/lib/systemd/random-seed"
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
          {
            file = "/etc/ssh/ssh_host_rsa_key";
            how = "symlink";
            configureParent = true;
          }
          {
            file = "/etc/ssh/ssh_host_rsa_key.pub";
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
              ".cache/BraveSoftware"
              ".cache/DankMaterialShell"
              ".cache/bat"
              ".cache/cliphist"
              ".cache/dconf"
              ".cache/fastfetch"
              ".cache/fontconfig"
              ".cache/fish"
              ".cache/gnome-desktop-thumbnailer"
              ".cache/gtk-4.0"
              ".cache/mesa_shader_cache"
              ".cache/nix"
              ".cache/quickshell"
              ".cache/qtshadercache-x86_64-little_endian-lp64"
              ".cache/starship"
              ".cache/thumbnails"
              ".cache/tinysparql"
              ".cache/tracker3"
              ".cache/zen"
              ".bun"
              ".config/BraveSoftware"
              ".config/DankMaterialShell"
              ".config/Thunar"
              ".config/VSCodium"
              ".config/Vencord"
              ".config/alacritty"
              ".config/bat"
              ".config/codex"
              ".config/dconf"
              ".config/dgop"
              ".config/faugus-launcher"
              ".config/fish"
              ".config/gh"
              ".config/ghostty"
              ".config/gtk-3.0"
              ".config/gtk-4.0"
              ".config/matugen"
              ".config/mise"
              ".config/niri"
              ".config/nixos"
              ".config/obsidian"
              ".config/ovpn"
              ".config/pi-agents"
              ".config/pulse"
              ".config/systemd/user"
              ".config/tailscale"
              ".config/xfce4"
              ".config/zed"
              ".gnupg"
              ".local/bin"
              ".local/lib"
              ".local/share/Steam"
              ".local/share/applications"
              ".local/share/color-schemes"
              ".local/share/dbus-1"
              ".local/share/direnv"
              ".local/share/fastmcp"
              ".local/share/fish"
              ".local/share/flatpak"
              ".local/share/gvfs-metadata"
              ".local/share/icons"
              ".local/share/keyrings"
              ".local/share/mime"
              ".local/share/mise"
              ".local/share/nautilus"
              ".local/share/nvim"
              ".local/share/pnpm"
              ".local/share/systemd"
              ".local/share/tinysparql"
              ".local/share/tracker3"
              ".local/share/umu"
              ".local/share/uv"
              ".local/share/warden"
              ".local/share/zed"
              ".local/share/zoxide"
              ".local/state/DankMaterialShell"
              ".local/state/home-manager"
              ".local/state/mise"
              ".local/state/nvim"
              ".local/state/nix"
              ".local/state/tinysparql"
              ".local/state/tracker3"
              ".local/state/tmux"
              ".local/state/wireplumber"
              ".mozilla"
              ".pki"
              ".steam"
              ".var/app"
              ".vscode-oss"
              ".zen"
              "Desktop"
              "Documents"
              "Downloads"
              "Faugus"
              "Games"
              "Music"
              "Mounts"
              "Pictures"
              "Projects"
              "Videos"
            ];
            files = [
              ".bash_history"
              ".local/share/recently-used.xbel"
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

    # /nix is implicitly boot-needed in NixOS, but keep it explicit for this
    # tmpfs-root layout. /persistent is needed in initrd for preserved early state.
    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persistent".neededForBoot = true;

    # /tmp is disk-backed through preservation, but should not survive reboots.
    boot.tmp.cleanOnBoot = true;

    # The password hash is supplied at install time with disko-install --extra-files.
    users.users.oj = {
      initialHashedPassword = lib.mkForce null;
      hashedPasswordFile = "/persistent/passwd";
    };

    swapDevices = [
      {
        device = "/persistent/swapfile";
        size = 32768;
      }
    ];
  };
}
