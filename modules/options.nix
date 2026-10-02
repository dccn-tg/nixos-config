{ lib, ... }:

{

  options.graphics.nvidia_gpu.enable = lib.mkEnableOption "NVIDIA GPU support";

}