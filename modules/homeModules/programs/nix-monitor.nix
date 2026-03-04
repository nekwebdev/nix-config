{inputs, ...}: {
  flake.homeModules.nixMonitor = {osConfig ? {}, ...}: let
    hostName = osConfig.networking.hostName or null;
    flakeRef = "~/.config/nixos#${hostName}";
  in {
    imports = [inputs.nix-monitor.homeManagerModules.default];

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
}
