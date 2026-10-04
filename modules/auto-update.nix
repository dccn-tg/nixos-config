# Pull-based updates with Comin: every machine follows GitHub main and builds its own class.
{ inputs, ... }:

{
  flake.modules.nixos.auto-update = { host, pkgs, ... }: {
    imports = [ inputs.comin.nixosModules.comin ];

    services.comin = {
      enable = true;
      # After a successful deployment, either flag /run/reboot-required (kernel, initrd or
      # modules changed) or write a one-line summary to /run/update-applied. The user
      # services reboot-reminder and update-notice (desktop-common) notify the user.
      postDeploymentCommand = pkgs.writeShellScript "comin-post-deployment" ''
        [ "$COMIN_STATUS" = done ] || exit 0
        for f in kernel initrd kernel-modules; do
          if [ "$(${pkgs.coreutils}/bin/readlink /run/booted-system/$f)" != "$(${pkgs.coreutils}/bin/readlink /run/current-system/$f)" ]; then
            ${pkgs.coreutils}/bin/touch /run/reboot-required
            exit 0
          fi
        done
        ${pkgs.coreutils}/bin/rm -f /run/reboot-required
        printf '%s (%s)\n' "$(printf '%s' "$COMIN_GIT_MSG" | ${pkgs.coreutils}/bin/head -n1)" "''${COMIN_GIT_SHA:0:7}" > /run/update-applied
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
