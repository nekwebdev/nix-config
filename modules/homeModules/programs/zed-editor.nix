{...}: {
  flake.homeModules.zedEditor = {pkgs, ...}: {
    programs.zed-editor = {
      enable = true;
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
