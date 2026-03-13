{...}: {
  flake.homeModules.zedEditor = {
    config,
    pkgs,
    ...
  }: let
    repoRoot = ../../../.;
    settingsPath = "${repoRoot}/configs/users/${config.home.username}/common/zed/settings.json";
    repoSettings =
      if builtins.pathExists settingsPath
      then builtins.fromJSON (builtins.readFile settingsPath)
      else {};
  in {
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
      mutableUserSettings = true;
      userSettings = repoSettings;
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
