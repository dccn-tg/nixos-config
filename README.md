# nixos-config

NixOS configuration managed with Flakes, structured with
[flake-parts](https://flake.parts) and the dendritic pattern: every file under
`modules/` is a flake-parts module (auto-loaded with
[import-tree](https://github.com/vic/import-tree)) that registers NixOS modules
as `flake.modules.nixos.<name>`. Nothing imports files by path.

## Layout

| File | Registers |
|---|---|
| `modules/base.nix` | `base`: locale, boot, networking, users, core tools (every host) |
| `modules/storage.nix` | `storage`: disko layout (LUKS + LVM + XFS) |
| `modules/hardware.nix` | `hw-vm`, `hw-latitude5491`, `hw-precision5560`, `hw-laptop`, `hw-nvidia` |
| `modules/desktops.nix` | `desktop-gnome`, `desktop-kde`, `desktop-sway` |
| `modules/roles.nix` | `role-norm`, `role-geek` (`geek` = `norm` + development features) |
| `modules/auto-update.nix` | `auto-update`: [Comin](https://github.com/nlewo/comin) pulls updates from GitHub `main` |
| `modules/hosts.nix` | builds a `nixosConfiguration` for every *class* |

The repository contains no per-machine files. A machine belongs to a **class**,
named `<model>-<desktop>-<role>[-sb]`, for example `latitude5491-gnome-norm`:

- model: `vm` | `latitude5491` | `precision5560` (disk device and default sizes are defined in `modules/hosts.nix`)
- desktop: `gnome` | `kde` | `sway`
- role: `norm` | `geek`
- `-sb` suffix: optional, adds Secure Boot (see below)

The hostname is machine state: the installer writes it to `/etc/hostname`.

## Installing NixOS with Flake

1. boot with the NixOS minimal ISO installer image into an interactive shell
2. setup network connection on the device
3. clone this repository
4. run the [`scripts/install.sh`](scripts/install.sh) script:

   ```bash
   sudo scripts/install.sh [-d gnome|kde|sway] [-r norm|geek] [-s root-size-gb] <hostname> <vm|latitude5491|precision5560>
   ```

   The `-s` option sets the root partition size in GB (default: `10`). The swap size is derived from the amount of RAM. The installation fails if root + swap exceeds the disk size minus 10 GB.

   During the installation, you will be asked to provide a password for the first `nixadmin` user.

5. reboot the system once the installation is completed.

## Automatic updates

Every machine runs Comin, which polls `https://github.com/dccn-tg/nixos-config` (branch `main`) every 30 minutes, then builds and switches to the machine's class. Comin never reboots; kernel updates apply at the next reboot.

## Adding a new hardware model

1. add a `hw-<model>` module in `modules/hardware.nix` (a nixos-hardware profile plus initrd modules; `nixos-generate-config` on a sample machine shows which ones)
2. add the model with its `diskDevice`, `rootSize` and `swapSize` to `models` in `modules/hosts.nix`

## Secure Boot (optional, experimental)

Secure Boot uses [lanzaboote](https://github.com/nix-community/lanzaboote), which is
still considered unstable, so it is off by default. To enable it on a host:

1. create the signing keys: `sudo nix run nixpkgs#sbctl -- create-keys` (stored in `/var/lib/sbctl`)
2. switch once, manually, to the `-sb` variant of the machine's class (Comin then follows it):
   `sudo nixos-rebuild switch --flake "github:dccn-tg/nixos-config#<class>-sb"`
3. check with `sudo sbctl verify`
4. put the firmware in Setup Mode and run `sudo sbctl enroll-keys --microsoft`
   __note:__ you may need to add `--ignore-immutable` option in case the command gives _File is immutable_ error.
5. reboot and enable Secure Boot in the firmware

Rebuild with the plain class name (without `-sb`) to return to systemd-boot.

## Manual update

To rebuild from a local checkout:

```bash
sudo nixos-rebuild switch --flake ".#<class>"
```
