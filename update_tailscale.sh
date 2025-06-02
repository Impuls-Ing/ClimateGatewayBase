#!/bin/bash
# This script is intended to simplify tailscale update
# It is intended to be called manually, so the outcome can be tested

CACHE="cache/"
TAILSCALE_URL="https://pkgs.tailscale.com/stable/"
TAILSCALE_FILENAME=$(curl -s "$TAILSCALE_URL" | grep -Po "href\=\"\Ktailscale\_\d+\.\d+\.\d+\_arm64.tgz")
TAILSCALE_BASENAME="${TAILSCALE_FILENAME%.*}"
ROOTFS_OVERLAY_DIR="rootfs-overlay/tailscale"

if [ ! -d "$CACHE" ]; then
    mkdir $CACHE
fi

wget -P "$CACHE" "${TAILSCALE_URL}/${TAILSCALE_FILENAME}"

mkdir -p "${ROOTFS_OVERLAY_DIR}/usr/sbin"
mkdir -p "${ROOTFS_OVERLAY_DIR}/usr/etc/default"
mkdir -p "${ROOTFS_OVERLAY_DIR}/usr/etc/systemd/system"

tar -xvf "${CACHE}/${TAILSCALE_FILENAME}" -C "${ROOTFS_OVERLAY_DIR}/usr/sbin/"

ln -sf "/usr/sbin/${TAILSCALE_BASENAME}/systemd/tailscaled.defaults" "${ROOTFS_OVERLAY_DIR}/usr/etc/default/tailscaled"
ln -sf "/usr/sbin/${TAILSCALE_BASENAME}/systemd/tailscaled.service" "${ROOTFS_OVERLAY_DIR}/usr/etc/systemd/system/tailscaled.service"
ln -sf "${TAILSCALE_BASENAME}/tailscale" "${ROOTFS_OVERLAY_DIR}/usr/sbin/tailscale"
ln -sf "${TAILSCALE_BASENAME}/tailscaled" "${ROOTFS_OVERLAY_DIR}/usr/sbin/tailscaled"
