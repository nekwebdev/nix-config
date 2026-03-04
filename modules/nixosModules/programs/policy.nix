{
  flake.nixosModules.policy = {
    lib,
    pkgs,
    ...
  }: {
    # HM-first exception: NetworkManager and firewall are host networking plumbing.
    networking.networkmanager.enable = true;
    networking.networkmanager.plugins = [pkgs.networkmanager-openvpn];
    networking.firewall.enable = true;

    # HM-first exception: sudo policy is a privileged system concern.
    security.sudo.wheelNeedsPassword = lib.mkForce true;

    # HM-first exception: login-shell handoff is host-wide shell policy for system bash.
    programs.bash.interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]; then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';

    # HM-first exception: dynamic linker compatibility for third-party binaries is system runtime plumbing.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        libcap
        xz
        openssl
        zlib
      ];
    };
  };
}
