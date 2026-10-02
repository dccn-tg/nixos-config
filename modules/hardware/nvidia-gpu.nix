{ ... }:

{
  ## disable NVIDIA discrete GPU
  services.xserver.videoDrivers = [ "modesetting" ];
  hardware.nvidia.modesetting.enable = false;
  hardware.nvidia.powerManagement.enable = false;
  hardware.graphics.enable = true;
}