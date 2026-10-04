# Basic security hardening applied to every host. Kept compatible with Flatpak, Firefox and
# rootless containers (user namespaces stay enabled) and with hibernation.
{
  flake.modules.nixos.hardening = { lib, ... }: {
    # No editing of the kernel command line at boot.
    boot.loader.systemd-boot.editor = false;

    boot.kernel.sysctl = {
      # kernel
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;

      # network (IPv6 stays enabled). rp_filter is loose (2) to keep VPNs working.
      "net.ipv4.conf.all.rp_filter" = 2;
      "net.ipv4.conf.default.rp_filter" = 2;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.default.log_martians" = 1;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    };

    # Rarely used network protocols and filesystems.
    boot.blacklistedKernelModules = [
      "dccp"
      "sctp"
      "rds"
      "tipc"
      "cramfs"
      "freevxfs"
      "hfs"
      "hfsplus"
    ];

    security.sudo.execWheelOnly = true;
    nix.settings.allowed-users = [ "@wheel" ];

    systemd.coredump.enable = false;
    services.journald.extraConfig = "SystemMaxUse=1G";

    networking.firewall.logRefusedConnections = true;
  };

  # Screen lock after 15 minutes of idle. Auto-lock cannot be turned off; users may still
  # change the timeout. Sway has none yet.
  flake.modules.nixos.hardening-gnome = { lib, ... }: {
    programs.dconf.profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/screensaver" = {
          lock-enabled = true;
          lock-delay = lib.gvariant.mkUint32 0;
        };
        "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 900;
      };
      locks = [ "/org/gnome/desktop/screensaver/lock-enabled" ];
    }];
  };

  flake.modules.nixos.hardening-kde = {
    environment.etc."xdg/kscreenlockerrc".text = ''
      [Daemon]
      Autolock[$i]=true
      LockOnResume[$i]=true
      LockGrace=0
      Timeout=15
    '';
  };

  flake.modules.nixos.hardening-sway = { };
}
