{...}: {
  flake.nixosModules.virtualization = {pkgs, ...}: {
    # HM-first exception: libvirt/QEMU daemon stack is privileged host virtualization plumbing.
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
        vhostUserPackages = [pkgs.virtiofsd];
      };
    };

    # HM-first exception: virt-manager integrates with system libvirtd and system dconf profile.
    programs.virt-manager.enable = true;

    # HM-first exception: USB passthrough helper is a privileged wrapper/capability.
    virtualisation.spiceUSBRedirection.enable = true;

    # HM-first exception: root-owned orchestration keeps libvirt default network ready.
    systemd.services.libvirt-default-network = {
      description = "Ensure libvirt default network is active and autostarts";
      wantedBy = ["multi-user.target"];
      after = [
        "libvirtd-config.service"
        "libvirtd.service"
      ];
      requires = ["libvirtd.service"];
      path = [pkgs.libvirt];
      serviceConfig.Type = "oneshot";
      script = ''
        if ! virsh --connect qemu:///system net-info default >/dev/null 2>&1; then
          exit 0
        fi

        virsh --connect qemu:///system net-autostart default
        virsh --connect qemu:///system net-start default >/dev/null 2>&1 || true
      '';
    };
  };
}
