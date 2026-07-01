{ pkgs, ... }:
{
  users.users.nixadmin = {

    isNormalUser = true;

    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];

    shell = pkgs.zsh;

    initialPassword = "ChangeMeImmediately";
  };
}
