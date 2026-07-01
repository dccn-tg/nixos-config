{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/vda2";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "xfs";
  };
}
