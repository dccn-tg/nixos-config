# Hardware axis (one module per model) and the NVIDIA mixin.
{ inputs, self, ... }:
let
  hw = inputs.nixos-hardware.nixosModules;
in
{
  flake.modules.nixos.hw-vm = { modulesPath, ... }: {
    # virtio drivers in the initrd, needed to find the disk and unlock LUKS at boot.
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

    # A system-wide daemon that talks to the hypervisor over a virtio serial port for
    # clipboard sharing, automatic resolution adjustment, file transfer and seamless
    # mouse integration (QEMU/KVM, VirtualBox, VMware).
    services.spice-vdagentd.enable = true;
  };

  flake.modules.nixos.hw-laptop = { pkgs, lib, modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/all-hardware.nix") ];

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

  # Closest known nixos-hardware profile (dell-latitude-5491 does not exist); not verified on the 5491.
  flake.modules.nixos.hw-latitude5491 = {
    imports = [ self.modules.nixos.hw-laptop hw.dell-latitude-5490 ];

    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "sd_mod" "sdhci_pci" "rtsx_pci_sdmmc" ];
    boot.kernelModules = [ "kvm-intel" ];
  };

  # Not the dell-precision-5560 profile: it enables NVIDIA PRIME. The dGPU is disabled instead.
  flake.modules.nixos.hw-precision5560 = {
    imports = [
      self.modules.nixos.hw-laptop
      hw.common-pc-laptop
      hw.common-pc-ssd
      hw.common-cpu-intel
      hw.common-gpu-nvidia-disable
    ];

    services.fwupd.enable = true;

    boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "sd_mod" ];
    boot.kernelModules = [ "kvm-intel" ];
  };

  flake.modules.nixos.hw-nvidia = { lib, ... }: {
    services.xserver.videoDrivers = [ "nvidia" ];
    local.allowedUnfree = [
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
