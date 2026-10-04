# Applied to every host.
{
  flake.modules.nixos.base = { pkgs, ... }: {
    imports = [
      ({ lib, config, ... }: {
        # Modules append the unfree packages they need; merged into one predicate.
        options.local.allowedUnfree = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        config.nixpkgs.config.allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) config.local.allowedUnfree;
      })
    ];

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

    # graphical boot splash, including the LUKS passphrase prompt
    boot.plymouth = {
      enable = true;
      theme = "spinner";
    };
    # Plymouth asks for the LUKS passphrase reliably only with the systemd initrd.
    boot.initrd.systemd.enable = true;
    boot.initrd.verbose = false;
    boot.consoleLogLevel = 3;
    boot.kernelParams = [
      "quiet"
      "splash"
      "udev.log_level=3"
      "rd.systemd.show_status=auto"
    ];

    # networking
    # Hostname is machine state: scripts/install.sh writes /etc/hostname.
    networking.hostName = "";
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

      git
      vim
      wget
      curl
      htop
      jq

      usbutils
      pciutils
      nvme-cli
    ];
  };
}
