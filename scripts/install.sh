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
# 1. Input validation
# ---------------------------------------------------------------------------

[[ $EUID -eq 0 ]] || die "This script must be run as root (use sudo)."

HOSTNAME="${1:-}"
DISK="${2:-}"

[[ -n "$HOSTNAME" ]] || die "Usage: $0 <hostname> <disk-device>"
[[ -n "$DISK"     ]] || die "Usage: $0 <hostname> <disk-device>"
[[ -b "$DISK"     ]] || die "Disk device '$DISK' not found or is not a block device."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_URL="https://github.com/dccn-tg/nixos-config"
REPO_DIR=$(cd "$SCRIPT_DIR/.." && git rev-parse --show-toplevel || "")

# ---------------------------------------------------------------------------
# 2. Collect secrets up front (nothing is written to disk or echoed)
# ---------------------------------------------------------------------------

info "Collecting secrets"

read -rsp "  Enter password for user 'nixadmin': " USER_PASS; echo
read -rsp "  Confirm password for user 'nixadmin': " USER_PASS2; echo
[[ "$USER_PASS" == "$USER_PASS2" ]] || die "User passwords do not match."
[[ ${#USER_PASS} -ge 6 ]] || die "User password must be at least 6 characters."

# ---------------------------------------------------------------------------
# 3. Confirmation prompt
# ---------------------------------------------------------------------------

printf '\n'
printf '\033[1;33mWARNING:\033[0m All data on %s will be permanently destroyed.\n' "$DISK"
printf '         Hostname : %s\n' "$HOSTNAME"
printf '         Disk     : %s\n' "$DISK"
printf '         Swap     : %s  (%d GB)\n' "$PART_SWAP" "$swapGB"
printf '\n'
read -rp "Type YES in uppercase to continue: " CONFIRM
[[ "$CONFIRM" == "YES" ]] || { echo "Aborted."; exit 0; }

# ---------------------------------------------------------------------------
# 8. Generate hardware configuration
# ---------------------------------------------------------------------------

info "Generating hardware configuration"
nixos-generate-config --root /mnt
ok "Hardware configuration written to /mnt/etc/nixos/"

# ---------------------------------------------------------------------------
# 9. Clone this repository
# ---------------------------------------------------------------------------
if [ "$REPO_DIR" == "" ]; then
    REPO_DIR="/mnt/etc/nixos/nixos-config"
    info "Cloning nixos-config into $REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
    ok "Repository cloned"
fi

# ---------------------------------------------------------------------------
# 10. Copy generated hardware configuration into the repo
# ---------------------------------------------------------------------------
info "Checking host specific configuration"
if [ ! -d "$REPO_DIR/hosts/${HOSTNAME}" ]; then
    mkdir -p "$REPO_DIR/hosts/${HOSTNAME}"
fi

info "Copying hardware configuration to $REPO_DIR/hosts/${HOSTNAME}/hardware.nix"
cp /mnt/etc/nixos/hardware-configuration.nix \
   "$REPO_DIR/host/${HOSTNAME}/hardware.nix"
git add "$REPO_DIR/host/${HOSTNAME}/hardware.nix"
ok "Hardware config copied"

# ---------------------------------------------------------------------------
# 11. Install NixOS
# ---------------------------------------------------------------------------

info "Creating disk partitions"
nixos-shell -p disko
disko --mode disko --flake "${REPO_DIR}#${HOSTNAME}"

info "Running nixos-install (this may take a while)"
nixos-install --no-root-passwd --flake "${REPO_DIR}#${HOSTNAME}"
ok "NixOS installation complete"

# ---------------------------------------------------------------------------
# 12. Set nixadmin password
# ---------------------------------------------------------------------------

info "Setting password for user 'nixadmin'"
nixos-enter --root /mnt -c \
    "printf '%s\n%s\n' '${USER_PASS}' '${USER_PASS2}' | passwd nixadmin"

# Overwrite the password variable now that it has been used.
USER_PASS="$(head -c 64 /dev/urandom | base64)"
USER_PASS2="$USER_PASS"

ok "Password set for nixadmin"

# ---------------------------------------------------------------------------
# 13. Done
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
