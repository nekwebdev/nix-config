{self, ...}: {
  flake.homeModules.userOj = {...}: {
    imports = [
      self.homeModules.userOjBase
      self.homeModules.userOjGit
      self.homeModules.userOjLotusPackages
      self.homeModules.userOjLotusSession
      self.homeModules.userOjLotusAppearance

      self.homeModules.base
      self.homeModules.environment
      self.homeModules.fish
      self.homeModules.aliasRegistry
      self.homeModules.aliasesCommon
      self.homeModules.bat
      self.homeModules.brave
      self.homeModules.eza
      self.homeModules.fastfetch
      self.homeModules.fzf
      self.homeModules.ghostty
      self.homeModules.mangohud
      self.homeModules.nixMonitor
      self.homeModules.starship
      self.homeModules.tlrc
      self.homeModules.vscode
      self.homeModules.zedEditor
      self.homeModules.zoxide
      self.homeModules.niri
      self.homeModules.dms
    ];
  };
}
