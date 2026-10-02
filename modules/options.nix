{ lib, ... }:

{

  options.graphics.nvidia_gpu.enable = lib.mkEnableOption "NVIDIA GPU support";

  options.host = {
    name = lib.mkOption {
      description = "The name of the host.";
      type = lib.types.str;
    };

    profile = lib.mkOption {
      description = "The profile of the host.";
      type = lib.types.enum [
        "laptop"
        "vm"
      ];
      default = "laptop";
    };

    diskDevice = lib.mkOption {
      description = "The disk device to use for the OS filesystem.";
      type = lib.types.str;
    };

    rootSize = lib.mkOption {
      description = "The size of the root partition.";
      type = lib.types.str;
      default = "50G";
    };

    swapSize = lib.mkOption {
      description = "The size of the swap partition.";
      type = lib.types.str;
      default = "16G";
    };
  };
}