# Applied to every host.
{
  flake.modules.nixos.base = { pkgs, host, ... }: {
    system.stateVersion = "26.05";

    time.timeZone = "Europe/Amsterdam";

    i18n.defaultLocale = "en_US.UTF-8";

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # boot
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # networking
    networking.hostName = host.name;
    networking.networkmanager.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
      allowPing = false;
    };

    # users
    users.users.nixadmin = {
      isNormalUser = true;

      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "input"
      ];

      shell = pkgs.zsh;

      initialPassword = "ChangeMeImmediately";
    };

    # core programs
    programs.zsh.enable = true;

    environment.systemPackages = with pkgs; [
      networkmanagerapplet
      openvpn
      eduvpn-client
      geteduroam

      git
      vim
      wget
      curl
      htop

      usbutils
      pciutils
      nvme-cli
    ];
  };
}
