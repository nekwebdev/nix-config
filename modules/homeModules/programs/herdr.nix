{inputs, ...}: {
  flake.homeModules.herdr = {pkgs, ...}: {
    # HM-first: Herdr is a user-scoped terminal workspace manager.
    home.packages = [
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
