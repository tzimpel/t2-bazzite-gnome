#!/bin/bash

set -ouex pipefail

### Install packages
dnf5 install -y podman-compose podman-docker

# Remove Broadcom WiFi blacklist (T2 MBP)
if [[ -f /usr/lib/modprobe.d/20-akmods.conf ]]; then
  sed -i '/^\s*blacklist\s\+brcmfmac\s*$/d' /usr/lib/modprobe.d/20-akmods.conf
fi