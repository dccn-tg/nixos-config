# Desktop axis (install-args `desktop`). Every desktop imports `desktop-common`.
{ self, ... }:

{
  flake.modules.nixos.desktop-common = { pkgs, ... }: {
    services.pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
    };

    security.rtkit.enable = true;

    services.flatpak.enable = true;

    environment.systemPackages = with pkgs; [
      firefox
      eduvpn-client
      geteduroam
      thunderbird
      libreoffice
      drawio
      nextcloud-client
    ];

    # Ensure the Flathub remote exists in each user's installation at login.
    # Retries because the user manager cannot wait for the system network target.
    systemd.user.services.flatpak-add-flathub = {
      description = "Add Flathub flatpak remote for the user";
      wantedBy = [ "default.target" ];
      unitConfig = {
        StartLimitIntervalSec = "10min";
        StartLimitBurst = 5;
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo";
        Restart = "on-failure";
        RestartSec = 30;
      };
    };

    # Remind the user to reboot after an update changed kernel, initrd or modules
    # (flag set by the Comin post-deployment command, see auto-update.nix).
    systemd.user.services.reboot-reminder = {
      description = "Remind the user to reboot after a system update";
      wantedBy = [ "default.target" ];
      path = [ pkgs.libnotify pkgs.systemd ];
      unitConfig.ConditionPathExists = "/run/reboot-required";
      serviceConfig = {
        Type = "oneshot";
        # Shorter than the timer interval so a pending notification cannot block the next one.
        TimeoutStartSec = "4min";
        ExecStart = pkgs.writeShellScript "reboot-reminder" ''
          action=$(notify-send --urgency=critical --app-name="System update" \
            --action=reboot="Reboot now" --action=later="Later" --wait \
            "Reboot required" "A system update needs a reboot to take effect.")
          [ "$action" = reboot ] && systemctl reboot
          exit 0
        '';
      };
    };

    systemd.user.paths.reboot-reminder = {
      wantedBy = [ "default.target" ];
      pathConfig.PathChanged = "/run/reboot-required";
    };

    # Repeat interval is 5 minutes for testing; use e.g. "0/4:00" (every 4 hours) in production.
    systemd.user.timers.reboot-reminder = {
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = "*:0/5";
    };
  };

  flake.modules.nixos.desktop-gnome = { pkgs, lib, ... }: {
    imports = [ self.modules.nixos.desktop-common ];

    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    environment.systemPackages = [ pkgs.gnome-software ];

    # Keep Log Out available in the system menu; locked so users cannot hide it.
    programs.dconf.profiles.user.databases = [{
      settings."org/gnome/desktop/lockdown".disable-log-out = false;
      locks = [ "/org/gnome/desktop/lockdown/disable-log-out" ];
    }];

    # Mail client with Exchange (EWS) support.
    programs.evolution = {
      enable = true;
      plugins = [ pkgs.evolution-ews ];
    };

    xdg.portal.enable = true;
    xdg.portal.extraPortals = lib.mkAfter [
      pkgs.xdg-desktop-portal-gnome
    ];
  };

  flake.modules.nixos.desktop-kde = { pkgs, ... }: {
    imports = [ self.modules.nixos.desktop-common ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = [
      pkgs.kdePackages.discover
      pkgs.kdePackages.flatpak-kcm
    ];
  };

  flake.modules.nixos.desktop-sway = { pkgs, lib, ... }: {
    imports = [ self.modules.nixos.desktop-common ];

    programs.sway.enable = true;
    services.displayManager.gdm.enable = true;

    # Mail client with Exchange (EWS) support.
    programs.evolution = {
      enable = true;
      plugins = [ pkgs.evolution-ews ];
    };

    xdg.portal.extraPortals = lib.mkAfter [
      pkgs.xdg-desktop-portal-wlr
    ];

    environment.systemPackages = with pkgs; [
      swaybg
      swayidle
      swaylock
      waybar
      wofi
      grim
      slurp
      wl-clipboard
      dunst
    ];
  };
}
