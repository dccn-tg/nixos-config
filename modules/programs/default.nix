{ pkgs, ... }:

{
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [

    git
    vim
    firefox
    wget
    curl
    htop

    usbutils
    pciutils
    nvme-cli

  ];
}
