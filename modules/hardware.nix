# Hardware axis (install-args `hardware`) and the NVIDIA mixin (install-args `nvidia`).
{
  # A system-wide daemon that talks to the hypervisor over a virtio serial port for
  # clipboard sharing, automatic resolution adjustment, file transfer and seamless
  # mouse integration (QEMU/KVM, VirtualBox, VMware).
  flake.modules.nixos.hw-vm = {
    services.spice-vdagentd.enable = true;
  };

  flake.modules.nixos.hw-laptop = { pkgs, lib, ... }: {
    hardware.enableRedistributableFirmware = true;
    services.fstrim.enable = true;

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    hardware.graphics.enable = true;
    services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];

    powerManagement.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    services.logind.settings.Login.HandleLidSwitch = "suspend";

    environment.systemPackages = with pkgs; [
      acpi
      lm_sensors
    ];
  };

  flake.modules.nixos.hw-nvidia = { lib, ... }: {
    services.xserver.videoDrivers = [ "nvidia" ];
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "nvidia-x11"
        "nvidia-settings"
        "nvidia-persistenced"
      ];

    # Open kernel modules need Turing or newer; set to false for older GPUs.
    hardware.nvidia.open = lib.mkDefault true;
    hardware.nvidia.modesetting.enable = true;
    hardware.nvidia.powerManagement.enable = true;
  };
}
