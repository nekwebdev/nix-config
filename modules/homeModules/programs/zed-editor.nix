{...}: {
  flake.homeModules.zedEditor = {pkgs, ...}: {
    programs.zed-editor = {
      enable = true;
      extraPackages = with pkgs; [
        nil
        nixd
        just
        toml
        git-firefly
      ];
    };
  };
}
