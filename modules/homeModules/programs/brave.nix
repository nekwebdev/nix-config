{...}: {
  flake.homeModules.brave = {pkgs, ...}: {
    programs.brave = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      ];
    };

    home.sessionVariables = {
      BROWSER = "brave";
    };
  };
}
