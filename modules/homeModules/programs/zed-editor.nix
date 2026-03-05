{...}: {
  flake.homeModules.zedEditor = {
    lib,
    pkgs,
    ...
  }: let
    runtimeConfigHelper = "../../../scripts/runtime-config-helper.sh";
  in {
    home.activation.zedRuntimeConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash ${runtimeConfigHelper} seed zed
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
