{ ... }:

{
  host = {
    name = "vm001";
    type = "vm";

    diskDevice = "/dev/vda";
    rootSize = "10G";
    swapSize = "4G";
  };

  imports = [
    ./hardware.nix
    ../../profiles/vm.nix
  ];
}