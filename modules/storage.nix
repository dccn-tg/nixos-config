# Disk layout: GPT, ESP + LUKS -> LVM (root, swap, home), sized from install-args.nix.
{
  flake.modules.nixos.storage = { host, ... }: {
    disko.devices = {
      disk.main = {
        type = "disk";
        device = host.diskDevice;

        content = {
          type = "gpt";

          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            luks = {
              size = "100%";

              content = {
                type = "luks";
                name = "cryptroot";

                settings.allowDiscards = true;

                content = {
                  type = "lvm_pv";
                  vg = "vg0";
                };
              };
            };
          };
        };
      };

      lvm_vg.vg0 = {
        type = "lvm_vg";

        lvs = {
          root = {
            size = host.rootSize;
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/";
              mountOptions = [ "noatime" ];
              extraArgs = [ "-L" "nixos" ];
            };
          };

          swap = {
            size = host.swapSize;
            content.type = "swap";
          };

          home = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/home";
              mountOptions = [ "noatime" ];
              extraArgs = [ "-L" "home" ];
            };
          };
        };
      };
    };
  };
}
