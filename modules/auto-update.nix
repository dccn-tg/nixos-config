# Pull-based updates with Comin: every machine follows GitHub main and builds its own class.
{ inputs, ... }:

{
  flake.modules.nixos.auto-update = { host, ... }: {
    imports = [ inputs.comin.nixosModules.comin ];

    services.comin = {
      enable = true;
      # The flake output is the class; the real hostname lives in /etc/hostname.
      hostname = host.class;
      remotes = [{
        name = "origin";
        url = "https://github.com/dccn-tg/nixos-config";
        branches.main.name = "main";
        poller.period = 1800;
      }];
    };
  };
}
