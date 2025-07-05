#!/bin/bash

# ============================================
# 🐚 FreeBSD QEMU First-Time Setup Script
# ============================================

# ========== CONFIGURATION ====================
DISK_FILE="freebsd.qcow2"
DISK_SIZE="20G"     # Change if you want more space
RAM="4096"          # 4GB RAM (adjust as needed)
CPUS="4"            # 4 CPU cores (adjust as needed)
BASE_URL="https://download.freebsd.org/ftp/releases/ISO-IMAGES"
# =============================================

echo "=========================================="
echo " 🔧 FreeBSD QEMU Setup"
echo "=========================================="

# ========== Fetch and List Available Versions ==========
echo "[*] Fetching available FreeBSD versions..."
VERSIONS=$(curl -s "$BASE_URL/" | grep -oP 'href="\K[0-9]+\.[0-9]+(?=/")' | sort -V | uniq)

if [ -z "$VERSIONS" ]; then
    echo "[!] Error: Failed to fetch version list from $BASE_URL"
    exit 1
fi

echo "Available FreeBSD Versions:"
select VERSION in $VERSIONS; do
    if [[ -n "$VERSION" ]]; then
        echo "[✔] Selected FreeBSD version: $VERSION"
        break
    else
        echo "[!] Invalid selection. Try again."
    fi
done

# ========== Build ISO URL and Filenames ==========
ISO_NAME="FreeBSD-${VERSION}-RELEASE-amd64-disc1.iso"
ISO_XZ="${ISO_NAME}.xz"
DOWNLOAD_URL="$BASE_URL/${VERSION}/${ISO_XZ}"

# ========== Download ISO ==========
if [ ! -f "$ISO_XZ" ]; then
    echo "[*] Downloading $ISO_XZ..."
    wget "$DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        echo "[!] Error: Download failed. Check your internet connection."
        exit 1
    fi
else
    echo "[✔] ISO archive already exists: $ISO_XZ"
fi

# ========== Extract ISO ==========
if [ ! -f "$ISO_NAME" ]; then
    echo "[*] Extracting $ISO_XZ..."
    xz -dk "$ISO_XZ"
    if [ $? -ne 0 ]; then
        echo "[!] Error: Failed to extract ISO."
        exit 1
    fi
else
    echo "[✔] ISO already extracted: $ISO_NAME"
fi

# ========== Create Disk Image ==========
if [ ! -f "$DISK_FILE" ]; then
    echo "[*] Creating virtual disk: $DISK_FILE ($DISK_SIZE)"
    qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"
    if [ $? -ne 0 ]; then
        echo "[!] Error: Failed to create disk image."
        exit 1
    fi
else
    echo "[✔] Virtual disk already exists: $DISK_FILE"
fi

# ========== Launch QEMU ==========
echo "[🚀] Launching FreeBSD $VERSION installer in QEMU..."
echo "[INFO] RAM: $RAM MB | CPUs: $CPUS | Disk: $DISK_FILE"

qemu-system-x86_64 \
  -enable-kvm \
  -m "$RAM" \
  -cdrom "$ISO_NAME" \
  -hda "$DISK_FILE" \
  -boot d \
  -smp "$CPUS" \
  -cpu host \
  -netdev user,id=n1,hostfwd=tcp::2222-:22 \
  -device e1000,netdev=n1

echo "=========================================="
echo " ✅ QEMU launched. Complete the FreeBSD installation in the window."
echo "    After installation, remove ISO and reboot from disk."
echo "=========================================="

