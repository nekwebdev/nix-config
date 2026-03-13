{...}: {
  flake.homeModules.zedEditor = {
    config,
    lib,
    pkgs,
    ...
  }: let
    repoRoot = ../../../.;
    runtimeConfigHelper = "${repoRoot}/scripts/runtime-config-helper.sh";
    runtimeUser = config.home.username or "";
  in {
    home.activation.zedRuntimeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/env \
        RUNTIME_CONFIG_USER=${lib.escapeShellArg runtimeUser} \
        ${pkgs.bash}/bin/bash ${runtimeConfigHelper} seed zed
    '';

    home.packages = [
      (pkgs.writeShellScriptBin "zed" ''
        if [ -x "${pkgs.zed-editor}/bin/zed" ]; then
          exec "${pkgs.zed-editor}/bin/zed" "$@"
        fi
        if [ -x "${pkgs.zed-editor}/bin/zeditor" ]; then
          exec "${pkgs.zed-editor}/bin/zeditor" "$@"
        fi
        echo "zed: zed-editor not found in ${pkgs.zed-editor}/bin" >&2
        exit 127
      '')
    ];

    programs.zed-editor = {
      enable = true;
      # comment out if using home manager for user settings
      # mutableUserSettings = true;
      extensions = [
        "catppuccin-blur"
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
