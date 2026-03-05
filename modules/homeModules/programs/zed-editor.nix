{...}: {
  flake.homeModules.zedEditor = {
    config,
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    repoRoot = ../../../.;
    runtimeConfigHelper = "${repoRoot}/scripts/runtime-config-helper.sh";
    runtimeUser = config.home.username or "";
    runtimeHost = osConfig.networking.hostName or "";
  in {
    home.activation.zedRuntimeConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/env \
        RUNTIME_CONFIG_USER=${lib.escapeShellArg runtimeUser} \
        RUNTIME_CONFIG_HOST=${lib.escapeShellArg runtimeHost} \
        ${pkgs.bash}/bin/bash ${runtimeConfigHelper} seed zed
    '';

    programs.zed-editor = {
      enable = true;
      extensions = [
        "git-firefly"
        "html"
        "just"
        "nix"
        "toml"
      ];
      extraPackages = with pkgs; [
        nil
        nixd
      ];
    };
  };
}
