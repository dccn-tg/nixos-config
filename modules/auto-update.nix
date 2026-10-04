# Pull-based updates with Comin: every machine follows GitHub main and builds its own class.
{ inputs, ... }:

{
  flake.modules.nixos.auto-update = { host, pkgs, ... }: {
    imports = [ inputs.comin.nixosModules.comin ];

    services.comin = {
      enable = true;
      # Flag /run/reboot-required when a deployment changed kernel, initrd or modules;
      # the reboot-reminder user service (desktop-common) notifies the user.
      postDeploymentCommand = pkgs.writeShellScript "comin-reboot-check" ''
        [ "$COMIN_STATUS" = done ] || exit 0
        for f in kernel initrd kernel-modules; do
          if [ "$(${pkgs.coreutils}/bin/readlink /run/booted-system/$f)" != "$(${pkgs.coreutils}/bin/readlink /run/current-system/$f)" ]; then
            ${pkgs.coreutils}/bin/touch /run/reboot-required
            exit 0
          fi
        done
        ${pkgs.coreutils}/bin/rm -f /run/reboot-required
      '';
      # The flake output is the class; the real hostname lives in /etc/hostname.
      hostname = host.class;
      remotes = [{
        name = "origin";
        url = "https://github.com/dccn-tg/nixos-config";
        branches.main.name = "main";
        poller.period = 300;
      }];
    };
  };
}
