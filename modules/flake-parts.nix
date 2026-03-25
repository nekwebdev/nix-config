{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.treefmt-nix.flakeModule];

  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
    description = "Home Manager modules exported by this flake.";
  };

  config = {
    systems = ["x86_64-linux"];

    perSystem = {config, ...}: {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.alejandra.enable = true;
      };

      formatter = config.treefmt.build.wrapper;
    };
  };
}
