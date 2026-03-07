{...}: {
  flake.homeModules.userOjBase = {lib, ...}: {
    home.stateVersion = "25.11";
    programs.home-manager.enable = true;

    home.activation.bootstrapPasswordReminder = lib.hm.dag.entryAfter ["writeBoundary"] ''
      state_dir="$HOME/.local/state/nix"
      reminder_file="$state_dir/password-bootstrap-reminder"
      ack_file="$state_dir/password-bootstrap-ack"

      $DRY_RUN_CMD mkdir -p "$state_dir"
      if [ ! -f "$ack_file" ]; then
        $DRY_RUN_CMD touch "$reminder_file"
      fi
    '';
  };
}
