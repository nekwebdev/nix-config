{inputs, ...}: {
  flake.homeModules.nixMonitor = {
    osConfig ? {},
    lib,
    ...
  }: let
    hostName = osConfig.networking.hostName or null;
    flakeRef = "~/.config/nixos#${hostName}";
    nixSweepEnabled =
      if osConfig ? services && osConfig.services ? nix-sweep
      then osConfig.services.nix-sweep.enable
      else false;
    nixSweepCfg = osConfig.services.nix-sweep or {};
    nixSweepGcCommand = lib.concatStringsSep " " (
      [
        "${nixSweepCfg.package}/bin/nix-sweep"
        "gc"
        "--non-interactive"
      ]
      ++ lib.optionals ((nixSweepCfg.gcBigger or null) != null) [
        "--bigger"
        (toString nixSweepCfg.gcBigger)
      ]
      ++ lib.optionals ((nixSweepCfg.gcQuota or null) != null) [
        "--quota"
        (toString nixSweepCfg.gcQuota)
      ]
      ++ lib.optionals (nixSweepCfg.gcModest or false) ["--modest"]
    );
    gcCommand =
      if nixSweepEnabled
      then [
        "bash"
        "-c"
        "sudo -n ${nixSweepGcCommand} 2>&1"
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
        "sudo nixos-rebuild dry-activate --flake ${flakeRef} 2>&1 && sudo nixos-rebuild test --flake ${flakeRef} 2>&1 && sudo nixos-rebuild switch --flake ${flakeRef} 2>&1"
      ];
    };
  };
}
