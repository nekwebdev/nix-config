{...}: {
  imports = [
    ./programs/system.nix
    ./programs/policy.nix
    ./programs/services.nix
    ./programs/nvidia.nix
    ./programs/gaming.nix
    ./programs/portals.nix
    ./programs/flatpak.nix
    ./programs/udev.nix
    ./programs/niri.nix
    ./programs/dms-greeter.nix
  ];
}
