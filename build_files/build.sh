#!/bin/bash

set -ouex pipefail

# Remove Broadcom WiFi blacklist (T2 MBP)
if [[ -f /usr/lib/modprobe.d/20-akmods.conf ]]; then
  sed -i '/^\s*blacklist\s\+brcmfmac\s*$/d' /usr/lib/modprobe.d/20-akmods.conf
fi

### Install packages
dnf5 install -y podman-compose podman-docker

### Add rEFInd management commands to ujust
install -D -m 0644 /ctx/60-custom.just /usr/share/ublue-os/just/60-custom.just
