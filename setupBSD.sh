#!/bin/bash

# ========== CONFIG ==========
ISO_XZ="FreeBSD-14.3-RELEASE-amd64-disc1.iso.xz"
ISO_FILE="FreeBSD-14.3-RELEASE-amd64-disc1.iso"
DISK_FILE="freebsd.qcow2"
DISK_SIZE="20G"
RAM="4096"       # 4GB RAM -- change the RAM as your need
CPUS="4"         # 4 CPU cores -- change the CPU cores as your need
# ============================

echo "[*] Checking if ISO is already extracted..."
if [ ! -f "$ISO_FILE" ]; then
    echo "[*] Extracting $ISO_XZ..."
    xz -dk "$ISO_XZ"
    if [ $? -ne 0 ]; then
        echo "[!] Extraction failed."
        exit 1
    fi
else
    echo "[*] ISO already extracted: $ISO_FILE"
fi

echo "[*] Checking for QEMU virtual disk"
if [ ! -f "$DISK_FILE" ]; then
    echo "[*] Creating virtual disk: $DISK_FILE ($DISK_SIZE)"
    qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"
else
    echo "[*] Virtual disk already exists: $DISK_FILE"
fi

echo "[*] Launching FreeBSD installer in QEMU"
qemu-system-x86_64 \
  -enable-kvm \
  -m "$RAM" \
  -cdrom "$ISO_FILE" \
  -hda "$DISK_FILE" \
  -boot d \
  -netdev user,id=n1,hostfwd=tcp::2222-:22 \
  -device e1000,netdev=n1 \
  -smp "$CPUS" \
  -cpu host

