# Desktop axis (install-args `desktop`). Every desktop imports `desktop-common`.
{ self, ... }:

{
  flake.modules.nixos.desktop-common = {
    services.pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
    };

    security.rtkit.enable = true;
  };

  flake.modules.nixos.desktop-gnome = { pkgs, lib, ... }: {
    imports = [ self.modules.nixos.desktop-common ];

    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    xdg.portal.enable = true;
    xdg.portal.extraPortals = lib.mkAfter [
      pkgs.xdg-desktop-portal-gnome
    ];
  };

  flake.modules.nixos.desktop-kde = {
    imports = [ self.modules.nixos.desktop-common ];

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.desktopManager.plasma6.enable = true;
  };

  flake.modules.nixos.desktop-sway = { pkgs, lib, ... }: {
    imports = [ self.modules.nixos.desktop-common ];

    programs.sway.enable = true;

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
