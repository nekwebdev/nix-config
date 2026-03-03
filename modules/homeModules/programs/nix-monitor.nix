{inputs, ...}: {
  flake.homeModules.nixMonitor = {
    lib,
    osConfig ? {},
    ...
  }: let
    hostName = osConfig.networking.hostName or null;
    isLotus = hostName == "lotus";
    flakeRef = "~/.config/nixos#${hostName}";
  in {
    imports = [inputs.nix-monitor.homeManagerModules.default];

    config = lib.mkIf isLotus {
      programs.nix-monitor = {
        enable = true;
        generationsCommand = [
          "bash"
          "-c"
          "find /nix/var/nix/profiles -maxdepth 1 -type l -name 'system-[0-9]*-link' | wc -l"
        ];
        rebuildCommand = [
          "bash"
          "-c"
          "sudo nixos-rebuild switch --flake ${flakeRef} 2>&1"
        ];
      };
    };
  };
}
