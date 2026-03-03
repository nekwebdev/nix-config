{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    fishInit = pkgs.writeText "fish-env-init.fish" ''
      set fish_greeting

      if type -q zoxide
        ${pkgs.lib.getExe pkgs.zoxide} init fish | source
      end
    '';
  in {
    packages.fish = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.fish;
      runtimeInputs = [pkgs.zoxide];
      flags = {
        "-C" = "source ${fishInit}";
      };
    };
  };
}
