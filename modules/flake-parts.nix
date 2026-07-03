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

  config = let
    repoRoot = ../.;
    treefmtRoot = lib.cleanSourceWith {
      src = repoRoot;
      filter = path: _: let
        pathString = toString path;
      in
        !(lib.hasSuffix "/.git" pathString || lib.hasInfix "/.git/" pathString);
    };
  in {
    systems = ["x86_64-linux"];

    perSystem = {config, ...}: {
      treefmt = {
        projectRoot = treefmtRoot;
        projectRootFile = "flake.nix";
        programs.alejandra.enable = true;
      };

      formatter = config.treefmt.build.wrapper;
    };
  };
}
