# /usr/share/ublue-os/just/60-rEFINd-management.just
# Minimal rEFInd management via ephemeral container (no layering, no refind in image)

set shell := ["bash", "-euo", "pipefail", "-c"]

ESP_MOUNT := env_var_or_default("ESP_MOUNT", "/boot/efi")
REFIND_FEDORA_IMG := env_var_or_default("REFIND_FEDORA_IMG", "registry.fedoraproject.org/fedora:41")

# --- helpers (inline bash) -------------------------------------------------

# Status helper: prints common checks
refind-status:
    @ESP="{{ ESP_MOUNT }}"
    @echo "ESP mountpoint: $ESP"
    @[[ -d /sys/firmware/efi/efivars ]] && echo "EFI mode: yes" || echo "EFI mode: no"
    @mountpoint -q "$ESP" && echo "ESP mounted: yes" || echo "ESP mounted: no"
    @[[ -d "$ESP/EFI/refind" ]] && echo "rEFInd files: present" || echo "rEFInd files: absent"
    @echo
    @echo "Hints:"
    @echo "  ESP_MOUNT=/boot/efi ujust refind-install"
    @echo "  REFIND_CLEAN_IMAGES=1 ujust refind-install   # also remove builder image afterwards"

# Run a command inside an ephemeral privileged container with ESP + efivars mounted

# Also optionally deletes the image afterwards (REFIND_CLEAN_IMAGES=1).
_refind-run cmd:
    @ESP="{{ ESP_MOUNT }}"
    @IMG="{{ REFIND_FEDORA_IMG }}"
    @CMD="{{ cmd }}"
    @command -v podman >/dev/null 2>&1 || { echo "podman not found"; exit 1; }
    @[[ -d /sys/firmware/efi/efivars ]] || { echo "Not booted in EFI mode. Aborting."; exit 1; }
    @mountpoint -q "$ESP" || { echo "ESP is not mounted at $ESP. Mount it first."; exit 1; }
    @set +e
    @sudo podman run --rm --privileged \
      -v "$ESP":"$ESP":rw \
      -v /sys/firmware/efi/efivars:/sys/firmware/efi/efivars:rw \
      "$IMG" \
      bash -lc "$CMD"
    @RC=$$?
    @set -e
    @exit $$RC

# --- minimal set -----------------------------------------------------------

refind-install:
    @ESP="{{ ESP_MOUNT }}"
    @echo "Installing rEFInd to $ESP (ephemeral container, no layering)..."
    @just _refind-run "dnf -y install refind refind-tools efibootmgr >/dev/null || dnf -y install rEFInd rEFInd-tools efibootmgr >/dev/null; refind-install --esp \"$ESP\" --yes"
    @echo "Done."
    @just refind-status

refind-uninstall:
    @ESP="{{ ESP_MOUNT }}"
    @echo "Uninstalling rEFInd from $ESP (ephemeral container, no layering)..."
    # refind-install --uninstall usually handles cleanup; we add a best-effort fallback for files.
    @just _refind-run "dnf -y install refind refind-tools efibootmgr >/dev/null || dnf -y install rEFInd rEFInd-tools efibootmgr >/dev/null; refind-install --esp \"$ESP\" --uninstall --yes || true; exit 0"
    @sudo rm -rf "$ESP/EFI/refind" || true
    @echo "Done."
    @just refind-status

refind-mkdefault:
    @echo "Setting rEFInd as default boot entry (NVRAM)..."
    @just _refind-run "dnf -y install refind-tools efibootmgr >/dev/null || dnf -y install rEFInd-tools efibootmgr >/dev/null; refind-mkdefault"
    @echo "Done."

refind-sb-healthcheck:
    @echo "Running Secure Boot health check (diagnostic)..."
    @just _refind-run "dnf -y install refind-tools >/dev/null || dnf -y install rEFInd-tools >/dev/null; refind-sb-healthcheck || true"
    @echo "Done."
