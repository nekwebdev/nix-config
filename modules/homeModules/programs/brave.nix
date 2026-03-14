{...}: {
  flake.homeModules.brave = {pkgs, ...}: {
    programs.brave = {
      enable = true;
      package = pkgs.brave;
      commandLineArgs = [
        "--ui-toolkit=gtk"
      ];
      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      ];
    };

    home.sessionVariables = {
      BROWSER = "brave";
    };
  };
}
