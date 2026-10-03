#!/usr/bin/env bash

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

info()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
die()   { printf '\n\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

swapGB=$(awk '/MemTotal/ {printf "%d", $2*1.2/1024/1024}' /proc/meminfo)

# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------

[[ $EUID -eq 0 ]] || die "This script must be run as root (use sudo)."

usage() {
    cat >&2 <<USAGE
Usage: $0 [options] <hostname> <hardware> <disk-device>

  hardware      hardware profile: vm | laptop

Options:
  -d <desktop>  desktop environment: gnome | kde | sway   (default: gnome)
  -r <role>     role: norm | geek                         (default: norm)
  -n            enable the NVIDIA GPU mixin
  -h            show this help
USAGE
    exit 1
}

DESKTOP="gnome"
ROLE="norm"
NVIDIA="false"

while getopts ":d:r:nh" opt; do
    case "$opt" in
        d) DESKTOP="$OPTARG" ;;
        r) ROLE="$OPTARG" ;;
        n) NVIDIA="true" ;;
        h) usage ;;
        :) die "Option -$OPTARG requires an argument." ;;
        *) die "Unknown option -$OPTARG. Use -h for help." ;;
    esac
done
shift $((OPTIND - 1))

HOSTNAME="${1:-}"
HARDWARE="${2:-}"
DISK="${3:-}"

[[ -n "$HOSTNAME" && -n "$HARDWARE" && -n "$DISK" ]] || usage
[[ -b "$DISK" ]] || die "Disk device '$DISK' not found or is not a block device."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_URL="https://github.com/dccn-tg/nixos-config"
REPO_DIR=$(cd "$SCRIPT_DIR/.." && git rev-parse --show-toplevel || "")

# ---------------------------------------------------------------------------
# Collect secrets up front (nothing is written to disk or echoed)
# ---------------------------------------------------------------------------

info "Collecting secrets"

read -rsp "  Enter password for user 'nixadmin': " USER_PASS; echo
read -rsp "  Confirm password for user 'nixadmin': " USER_PASS2; echo
[[ "$USER_PASS" == "$USER_PASS2" ]] || die "User passwords do not match."
[[ ${#USER_PASS} -ge 6 ]] || die "User password must be at least 6 characters."

# ---------------------------------------------------------------------------
# Confirmation prompt
# ---------------------------------------------------------------------------

printf '\n'
printf '\033[1;33mWARNING:\033[0m All data on %s will be permanently destroyed.\n' "$DISK"
printf '         Hostname : %s\n' "$HOSTNAME"
printf '         Disk     : %s\n' "$DISK"
printf '         Hardware : %s (nvidia: %s)\n' "$HARDWARE" "$NVIDIA"
printf '         Desktop  : %s\n' "$DESKTOP"
printf '         Role     : %s\n' "$ROLE"
printf '         Swap     : %d GB\n' "$swapGB"
printf '\n'
read -rp "Type YES in uppercase to continue: " CONFIRM
[[ "$CONFIRM" == "YES" ]] || { echo "Aborted."; exit 0; }

# ---------------------------------------------------------------------------
# Generate hardware configuration and copy it into the repo
# ---------------------------------------------------------------------------

info "Generating hardware configuration"
nixos-generate-config --root /mnt
ok "Hardware configuration written to /mnt/etc/nixos/"

REPO_DIR_HOST="$REPO_DIR/hosts/${HOSTNAME}"
info "Copying hardware configuration to $REPO_DIR_HOST/hardware.nix"
mkdir -p "$REPO_DIR_HOST"

cp /mnt/etc/nixos/hardware-configuration.nix "$REPO_DIR_HOST/hardware.nix"
git add "$REPO_DIR_HOST/hardware.nix"
ok "Hardware config copied"

info "Creating host-specfic installation arguments in $REPO_DIR_HOST/install-args.nix"
cat > "$REPO_DIR_HOST/install-args.nix" <<EOF
{
  # Hostname of the machine
  name = "${HOSTNAME}";
  # Hardware profile (modules/hardware.nix: hw-<hardware>)
  hardware = "${HARDWARE}";
  # Enable the NVIDIA GPU mixin (hw-nvidia)
  nvidia = ${NVIDIA};
  # Desktop environment (modules/desktops.nix: desktop-<desktop>)
  desktop = "${DESKTOP}";
  # Role of the machine (modules/roles.nix: role-<role>)
  role = "${ROLE}";
  # Disk device to use for the OS filesystem
  diskDevice = "${DISK}";
  # Size of the root partition
  # FIXME: should be determined dynamically based on disk size and swap size
  rootSize = "10G";
  # Size of the swap partition
  swapSize = "${swapGB}G";
}
EOF

git add "$REPO_DIR_HOST/install-args.nix"
ok "Installation arguments written"

# ---------------------------------------------------------------------------
# Install NixOS
# ---------------------------------------------------------------------------

info "Creating disk partitions"
nix-shell -p disko --run "disko --mode disko --flake \"${REPO_DIR}#${HOSTNAME}\""

info "Running nixos-install (this may take a while)"
nixos-install --no-root-passwd --flake "${REPO_DIR}#${HOSTNAME}"
ok "NixOS installation complete"

# ---------------------------------------------------------------------------
# Set nixadmin password
# ---------------------------------------------------------------------------

info "Setting password for user 'nixadmin'"
nixos-enter --root /mnt -c \
    "printf '%s\n%s\n' '${USER_PASS}' '${USER_PASS2}' | passwd nixadmin"

# Overwrite the password variable now that it has been used.
USER_PASS="$(head -c 64 /dev/urandom | base64)"
USER_PASS2="$USER_PASS"

ok "Password set for nixadmin"

# ---------------------------------------------------------------------------
# Copy repository to /mnt/home/nixadmin/nixos-config
# ---------------------------------------------------------------------------

mkdir -p /mnt/etc/nixos/nixos-config &&
    cp -R "$REPO_DIR" /mnt/etc/nixos/nixos-config

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

printf '\n'
printf '\033[1;32m====================================================\033[0m\n'
printf '\033[1;32m  Installation complete!\033[0m\n'
printf '\033[1;32m====================================================\033[0m\n'
printf '\n'
printf '  Next steps:\n'
printf '    1. Remove the installer media.\n'
printf '    2. Run: reboot\n'
printf '    3. Enter the LUKS passphrase when prompted by the bootloader.\n'
printf '    4. Log in as nixadmin with the password you just set.\n'
printf '    5. Change your password immediately: passwd\n'
printf '\n'
