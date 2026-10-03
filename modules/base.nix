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

    # garbage collection
    nix.gc = {
      automatic = true;
      dates = "weekly";
      randomizedDelaySec = "45min";
      persistent = true;
      options = "--delete-older-than 14d";
    };
    nix.optimise = {
      automatic = true;
      dates = [ "03:45" ];
    };
    nix.settings.min-free = 1024 * 1024 * 1024;
    nix.settings.max-free = 5 * 1024 * 1024 * 1024;

    # boot
    boot.loader.systemd-boot.configurationLimit = 5;
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
