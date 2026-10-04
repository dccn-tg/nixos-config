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
Usage: $0 [options] <hostname> <model>

  hostname      hostname of the machine
  model         hardware model: vm | latitude5491 | precision5560

Options:
  -d <desktop>  desktop environment: gnome | kde | sway   (default: gnome)
  -r <role>     role: norm | geek                         (default: norm)
  -s <size>     root partition size in GB                 (default: 10)
  -h            show this help
USAGE
    exit 1
}

DESKTOP="gnome"
ROLE="norm"
ROOT_GB="10"

while getopts ":d:r:s:h" opt; do
    case "$opt" in
        d) DESKTOP="$OPTARG" ;;
        r) ROLE="$OPTARG" ;;
        s) ROOT_GB="$OPTARG" ;;
        h) usage ;;
        :) die "Option -$OPTARG requires an argument." ;;
        *) die "Unknown option -$OPTARG. Use -h for help." ;;
    esac
done
shift $((OPTIND - 1))

HOSTNAME="${1:-}"
MODEL="${2:-}"

[[ -n "$HOSTNAME" && -n "$MODEL" ]] || usage
[[ "$ROOT_GB" =~ ^[1-9][0-9]*$ ]] || die "Root size must be a positive integer (GB)."

CLASS="${MODEL}-${DESKTOP}-${ROLE}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_DIR=$(cd "$SCRIPT_DIR/.." && git rev-parse --show-toplevel)

nix eval "${REPO_DIR}#nixosConfigurations.\"${CLASS}\".config.system.build.toplevel.drvPath" >/dev/null 2>&1 \
    || die "Unknown class '${CLASS}'. Check the model, desktop and role."

DISK=$(nix eval --raw "${REPO_DIR}#nixosConfigurations.\"${CLASS}\".config.disko.devices.disk.main.device")
[[ -b "$DISK" ]] || die "Disk device '$DISK' (from class ${CLASS}) not found or is not a block device."

diskGB=$(( $(blockdev --getsize64 "$DISK") / 1024 / 1024 / 1024 ))
requiredGB=$(( ROOT_GB + swapGB ))
maxGB=$(( diskGB - 10 )) # reserve 10 GB for other partitions (boot and home)
(( requiredGB <= maxGB )) || die "Root (${ROOT_GB} GB) + swap (${swapGB} GB) = ${requiredGB} GB exceeds the allowed ${maxGB} GB (disk ${diskGB} GB minus 10 GB reserve)."

# Sizes are read by storage.nix at install time only.
export ROOT_SIZE="${ROOT_GB}G" SWAP_SIZE="${swapGB}G"

# ---------------------------------------------------------------------------
# Collect secrets up front
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
printf '         hostname : %s\n' "$HOSTNAME"
printf '         disk     : %s (%d GB)\n' "$DISK" "$diskGB"
printf '           - root : %d GB\n' "$ROOT_GB"
printf '           - swap : %d GB\n' "$swapGB"
printf '         model    : %s\n' "$MODEL"
printf '         class    : %s\n' "$CLASS"
printf '         desktop  : %s\n' "$DESKTOP"
printf '         role     : %s\n' "$ROLE"
printf '\n'
read -rp "Type YES in uppercase to continue: " CONFIRM
[[ "$CONFIRM" == "YES" ]] || { echo "Aborted."; exit 0; }

# ---------------------------------------------------------------------------
# Install NixOS
# ---------------------------------------------------------------------------

info "Creating disk partitions"
nix-shell -p disko --run "disko --impure --mode disko --flake \"${REPO_DIR}#${CLASS}\""

info "Running nixos-install (this may take a while)"
nixos-install --impure --no-root-passwd --flake "${REPO_DIR}#${CLASS}"

mkdir -p /mnt/etc
printf '%s\n' "$HOSTNAME" > /mnt/etc/hostname
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
