
{ config, ... }:

let
  cfg = config.graphics;
in
{

  hardware.graphics.enable = true;

  services.xserver.videoDrivers =
    if cfg.nvidia_gpu.enable
    then [ "nvidia" ]
    else [ "modesetting" ];

  hardware.nvidia.modesetting.enable = cfg.nvidia_gpu.enable;
  hardware.nvidia.powerManagement.enable = cfg.nvidia_gpu.enable;

}