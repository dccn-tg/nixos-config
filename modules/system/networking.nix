{ pkgs, ... }:

let
  cfg = config.host;
in
{
  networking.networkmanager.enable = true;

  networking.hostName = cfg.name;

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    openvpn
  ];

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

}
