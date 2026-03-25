{inputs, ...}: {
  flake.homeModules.nixMonitor = {osConfig ? {}, ...}: let
    hostName = osConfig.networking.hostName or null;
    flakeRef = "~/.config/nixos#${hostName}";
    nixSweepEnabled =
      if osConfig ? services && osConfig.services ? nix-sweep
      then osConfig.services.nix-sweep.enable
      else false;
    gcCommand =
      if nixSweepEnabled
      then [
        "bash"
        "-c"
        "sudo systemctl start --wait nix-sweep.service 2>&1 && sudo systemctl start --wait nix-sweep-gc.service 2>&1"
      ]
      else [
        "sh"
        "-c"
        "nix-collect-garbage -d 2>&1"
      ];
  in {
    imports = [inputs.nix-monitor.homeManagerModules.default];

    programs.nix-monitor = {
      enable = true;
      inherit gcCommand;
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
