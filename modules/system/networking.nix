{ pkgs, host, ... }:

{
  networking.networkmanager.enable = true;

  networking.hostName = host.name;

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
