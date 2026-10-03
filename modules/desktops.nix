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

    # Add the Flathub remote to each user's installation on first login.
    systemd.user.services.flatpak-add-flathub = {
      description = "Add Flathub flatpak remote for the user";
      wantedBy = [ "default.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig.ConditionPathExists = "!%h/.local/share/flatpak/.flathub-added";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "flatpak-add-flathub" ''
          ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
          mkdir -p "$HOME/.local/share/flatpak"
          touch "$HOME/.local/share/flatpak/.flathub-added"
        '';
      };
    };
  };

  flake.modules.nixos.desktop-gnome = { pkgs, lib, ... }: {
    imports = [ self.modules.nixos.desktop-common ];

    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    environment.systemPackages = [ pkgs.gnome-software ];

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

    environment.systemPackages = with pkgs.kdePackages; [
      discover
      flatpak-kcm
    ];
  };

  flake.modules.nixos.desktop-sway = { pkgs, lib, ... }: {
    imports = [ self.modules.nixos.desktop-common ];

    programs.sway.enable = true;
    services.displayManager.gdm.enable = true;

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
