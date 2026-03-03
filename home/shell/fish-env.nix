{wrappedPrograms, ...}: {
  programs.fish = {
    enable = true;
    package = wrappedPrograms.fish;
  };
  home.packages = [wrappedPrograms.fish-env];
}
