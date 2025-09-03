#!/usr/bin/env bash

echo "=============================="
echo "🧠 FreeBSD QEMU Setup Script "
echo "=============================="

# ---------- CONFIGURATION ----------
DISK_FILE="freebsd.qcow2"
DISK_SIZE="20G"
RAM="4096"
CPUS="4"
BASE_URL="https://download.freebsd.org/releases/ISO-IMAGES"
ISO_DIR="isos"
mkdir -p "$ISO_DIR"

# ---------- RESOURCE CUSTOMIZATION ----------
echo ""
echo " Default Resources:"
echo "    ➤ CPUs : $CPUS"
echo "    ➤ RAM  : $RAM MB"
echo "    ➤ Disk : $DISK_SIZE"

read -p "✨ Do you want to customize CPU/RAM/Disk? (y/N): " CUSTOMIZE
CUSTOMIZE=${CUSTOMIZE,,}

if [[ "$CUSTOMIZE" == "y" ]]; then
    read -p "Enter CPU cores (default: $CPUS): " USER_CPUS
    [[ "$USER_CPUS" =~ ^[0-9]+$ ]] && CPUS="$USER_CPUS"

    read -p "Enter RAM in MB (default: $RAM): " USER_RAM
    [[ "$USER_RAM" =~ ^[0-9]+$ ]] && RAM="$USER_RAM"

    read -p "Enter disk size (e.g., 25G) (default: $DISK_SIZE): " USER_DISK
    [[ "$USER_DISK" =~ ^[0-9]+[GgMm]?$ ]] && DISK_SIZE="$USER_DISK"
fi

echo ""
echo "🚀 Final Configuration:"
echo "    ➤ CPUs : $CPUS"
echo "    ➤ RAM  : $RAM MB"
echo "    ➤ Disk : $DISK_SIZE"

# ---------- REQUIRED TOOLS ----------
REQUIRED_TOOLS=("curl" "wget" "xz" "qemu-img" "qemu-system-x86_64")
MISSING_TOOLS=()
echo "🔍 Checking for required tools..."

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "⚠️ Missing dependencies: ${MISSING_TOOLS[*]}"
    echo -n "🌐 Checking internet... "
    if ping -c 1 google.com &>/dev/null; then
        echo "connected."
    else
        echo "❌ No internet connection. Cannot auto-install packages."
        echo "🛑 Please install manually: ${MISSING_TOOLS[*]}"
        exit 1
    fi

    echo "📦 Installing missing packages..."
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y "${MISSING_TOOLS[@]}"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "${MISSING_TOOLS[@]}"
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm "${MISSING_TOOLS[@]}"
    elif command -v pkg &>/dev/null; then
        sudo pkg install -y "${MISSING_TOOLS[@]}"
    else
        echo "❌ No supported package manager found."
        exit 1
    fi
else
    echo "[✔] All required tools found."
fi

# ---------- FETCH LATEST VERSION ----------
echo "[*] Fetching available FreeBSD versions..."
VERSIONS=$(curl -s "$BASE_URL/" | grep -oP 'href="\K[0-9]+\.[0-9]+(?=/")' | sort -V | uniq)

if [ -z "$VERSIONS" ]; then
    echo "[!] Could not fetch version list from $BASE_URL"
    exit 1
fi

LATEST=$(echo "$VERSIONS" | tail -n 1)
echo "Available FreeBSD Versions: $VERSIONS"
echo "Latest version detected: $LATEST"
read -p "Do you want to use the latest ($LATEST)? (Y/n): " USE_LATEST
USE_LATEST=${USE_LATEST,,}

if [[ "$USE_LATEST" == "n" ]]; then
    select VERSION in $VERSIONS; do
        [[ -n "$VERSION" ]] && break
    done
else
    VERSION="$LATEST"
fi

echo "[✔] Selected FreeBSD version: $VERSION"

ISO_NAME="FreeBSD-${VERSION}-RELEASE-amd64-disc1.iso"
ISO_XZ="${ISO_NAME}.xz"
ISO_PATH="${ISO_DIR}/${ISO_NAME}"
ISO_XZ_PATH="${ISO_DIR}/${ISO_XZ}"
DOWNLOAD_URL="$BASE_URL/${VERSION}/${ISO_XZ}"

if [ ! -f "$ISO_PATH" ]; then
    echo "[*] Downloading $ISO_XZ..."
    wget -O "$ISO_XZ_PATH" "$DOWNLOAD_URL" || { echo "[!] Download failed"; exit 1; }

    echo "[*] Extracting ISO..."
    xz -dk "$ISO_XZ_PATH" || { echo "[!] Extraction failed"; exit 1; }
fi

# ---------- CREATE DISK ----------
if [ ! -f "$DISK_FILE" ]; then
    echo "[*] Creating virtual disk: $DISK_FILE ($DISK_SIZE)"
    qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE" || { echo "[!] Disk creation failed"; exit 1; }
else
    echo "[✔] Virtual disk already exists: $DISK_FILE"
fi

# ---------- KVM CHECK ----------
echo "🔍 Checking KVM support..."
if grep -E -c '(vmx|svm)' /proc/cpuinfo >/dev/null; then
    echo "✅ CPU supports virtualization."
else
    echo "❌ Your CPU does not support virtualization."
    exit 1
fi

if [ ! -e /dev/kvm ]; then
    echo "⚠️ /dev/kvm not found. Trying to load modules..."
    if grep -q vmx /proc/cpuinfo; then
        sudo modprobe kvm_intel
    elif grep -q svm /proc/cpuinfo; then
        sudo modprobe kvm_amd
    fi
    [ ! -e /dev/kvm ] && echo "❌ KVM not available. Enable in BIOS." && exit 1
fi

# ---------- LAUNCH VM ----------
echo ""
echo "[🚀] Launching FreeBSD installer..."
qemu-system-x86_64 \
  -enable-kvm \
  -m "$RAM" \
  -cdrom "$ISO_PATH" \
  -hda "$DISK_FILE" \
  -boot d \
  -smp "$CPUS" \
  -cpu host \
  -netdev user,id=n1,hostfwd=tcp::2222-:22 \
  -device e1000,netdev=n1

echo "=========================================="
echo " ✅ FreeBSD installer booted."
echo " 💡 After install, remove ISO and boot from disk."
echo "=========================================="


