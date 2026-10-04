# Secure Boot via lanzaboote (the `-sb` class variant). Opt-in: lanzaboote is still
# considered unstable. See README for the key creation and enrollment steps.
{
  flake.modules.nixos.secureboot = { lib, pkgs, ... }: {
    environment.systemPackages = [ pkgs.sbctl ];

    # lanzaboote replaces systemd-boot (enabled in base).
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
