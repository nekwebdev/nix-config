{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  systems = ["x86_64-linux"];

  perSystem = {config, ...}: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.alejandra.enable = true;
    };

    formatter = config.treefmt.build.wrapper;
  };
}
