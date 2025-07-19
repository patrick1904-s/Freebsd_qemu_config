#!/usr/bin/env bash

echo "=============================="
echo "🧠 FreeBSD QEMU Setup Script "
echo " ============================="

# ---------- CONFIGURATION ----------
DISK_FILE="freebsd.qcow2"
DISK_SIZE="20G"
RAM="4096"
CPUS="4"
BASE_URL="https://download.freebsd.org/ftp/releases/ISO-IMAGES"
ISO_DIR="isos"
mkdir -p "$ISO_DIR"
# ---------- RESOURCE CUSTOMIZATION ----------
echo ""
echo " Default Resources:"
echo "    ➤ CPUs : $CPUS"
echo "    ➤ RAM  : $RAM MB"
echo "    ➤ Disk : $DISK_SIZE"

read -p "✨ Do you want to customize CPU/RAM/Disk? (y/N): " CUSTOMIZE
CUSTOMIZE=${CUSTOMIZE,,}  # Convert to lowercase

if [[ "$CUSTOMIZE" == "y" ]]; then
    read -p "Enter CPU cores (default: $CPUS): " USER_CPUS
    if [[ "$USER_CPUS" =~ ^[0-9]+$ ]]; then
        CPUS="$USER_CPUS"
    fi

    read -p "Enter RAM in MB (default: $RAM): " USER_RAM
    if [[ "$USER_RAM" =~ ^[0-9]+$ ]]; then
        RAM="$USER_RAM"
    fi

    read -p "Enter disk size (e.g., 25G) (default: $DISK_SIZE): " USER_DISK
    if [[ "$USER_DISK" =~ ^[0-9]+[GgMm]?$ ]]; then
        DISK_SIZE="$USER_DISK"
    fi
fi
echo ""
echo "🚀 Final Configuration:"
echo "    ➤ CPUs : $CPUS"
echo "    ➤ RAM  : $RAM MB"
echo "    ➤ Disk : $DISK_SIZE"

# -----------------------------------

echo "=========================================="
echo " 🔧 FreeBSD QEMU Setup with Auto-Installer"
echo "=========================================="

# ---------- REQUIRED TOOLS ----------
REQUIRED_TOOLS=("curl" "wget" "xz" "qemu-img" "qemu-system-x86_64")
MISSING_TOOLS=()
echo "🔍 Checking for required tools..."

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

# ---------- AUTO-INSTALL IF MISSING ----------
if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "⚠️ Missing dependencies: ${MISSING_TOOLS[*]}"
    
    # Check internet connection
    echo -n "🌐 Checking internet... "
    if ping -c 1 google.com &>/dev/null; then
        echo "connected."
    else
        echo "❌ No internet connection. Cannot auto-install packages."
        echo "🛑 Please install these manually: ${MISSING_TOOLS[*]}"
        # Continue workflow anyway
        MISSING_TOOLS=()
    fi

    echo "📦 Attempting to install missing packages..."

    # Detect package manager
    if command -v apt &>/dev/null; then
        sudo apt update
        sudo apt install -y "${MISSING_TOOLS[@]}"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "${MISSING_TOOLS[@]}"
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm "${MISSING_TOOLS[@]}"
    elif command -v pkg &>/dev/null; then
        sudo pkg install -y "${MISSING_TOOLS[@]}"
    else
        echo "❌ No supported package manager found (apt, dnf, pacman, pkg)."
        echo "🛠️ Please install tools manually: ${MISSING_TOOLS[*]}"
    fi
else
    echo "[✔] All required tools found."
fi
# ----------------------------------

# ---------- SCAN FOR EXISTING ISO ----------
FOUND_ISO=""
FOUND_XZ=""
for f in *.iso; do
  [[ -f "$f" ]] && FOUND_ISO="$f" && break
done
for x in *.iso.xz; do
  [[ -f "$x" ]] && FOUND_XZ="$x" && break
done

# ---------- ASK TO USE EXISTING FILE ----------
if [[ -n "$FOUND_ISO" || -n "$FOUND_XZ" ]]; then
  echo "⚠️ Found existing FreeBSD file:"
  [[ -n "$FOUND_ISO" ]] && echo "    ➤ $FOUND_ISO"
  [[ -n "$FOUND_XZ" ]] && echo "    ➤ $FOUND_XZ"
  echo "Would you like to:"
  echo "  [1] Use this file"
  echo "  [2] Delete it and download a fresh one"
  echo "  [3] Ignore and continue (auto-detect latest)"
  read -p "Enter choice [1/2/3]: " USE_EXISTING

  case "$USE_EXISTING" in
    1)
      if [[ -n "$FOUND_XZ" ]]; then
        xz -dk "$FOUND_XZ"
        ISO_NAME="${FOUND_XZ%.xz}"
      else
        ISO_NAME="$FOUND_ISO"
      fi
      ;;
    2)
      echo "[*] Removing old ISO files..."
      [[ -n "$FOUND_ISO" ]] && rm "$FOUND_ISO"
      [[ -n "$FOUND_XZ" ]] && rm "$FOUND_XZ"
      ;;
    3)
      echo "[*] Continuing with download logic..."
      ;;
    *)
      echo "[!] Invalid choice. Exiting."
      exit 1
      ;;
  esac
fi

# ---------- FETCH VERSIONS ----------
if [[ -z "$ISO_NAME" ]]; then
  echo "[*] Fetching available FreeBSD versions..."
  VERSIONS=$(curl -s "$BASE_URL/" | grep -oP 'href="\K[0-9]+\.[0-9]+(?=/")' | sort -V | uniq)

  if [ -z "$VERSIONS" ]; then
    echo "[!] Could not fetch version list from $BASE_URL"
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

  ISO_NAME="FreeBSD-${VERSION}-RELEASE-amd64-disc1.iso"
  ISO_XZ="${ISO_NAME}.xz"
  ISO_PATH="${ISO_DIR}/${ISO_NAME}"
  ISO_XZ_PATH="${ISO_DIR}/${ISO_XZ}"
  DOWNLOAD_URL="$BASE_URL/${VERSION}/${ISO_XZ}"

  if [ ! -f "$ISO_XZ_PATH" ]; then
      echo "[*] Downloading $ISO_XZ..."
      wget -O "$ISO_XZ_PATH" "$DOWNLOAD_URL"
      if [ $? -ne 0 ]; then
          echo "[!] Failed to download ISO."
          exit 1
      fi
  fi

  if [ ! -f "$ISO_PATH" ]; then
      echo "[*] Extracting ISO..."
      xz -dk "$ISO_XZ_PATH"
      if [ $? -ne 0 ]; then
          echo "[!] Extraction failed."
          exit 1
      fi
  fi
  ISO_NAME="$ISO_PATH"
fi

# ---------- CREATE DISK ----------
if [ ! -f "$DISK_FILE" ]; then
    echo "[*] Creating virtual disk: $DISK_FILE ($DISK_SIZE)"
    qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"
    if [ $? -ne 0 ]; then
        echo "[!] Disk image creation failed."
        exit 1
    fi
else
    echo "[✔] Virtual disk already exists: $DISK_FILE"
fi
#---------Verifiaction of KVM is presernt or not ---------------
#!/bin/bash

echo "🔍 Checking KVM support..."

# Check if CPU supports virtualization
if grep -E -c '(vmx|svm)' /proc/cpuinfo >/dev/null; then
    echo "✅ CPU supports virtualization."
else
    echo "❌ Your CPU does not support virtualization. Exiting."
    exit 1
fi

# Check if /dev/kvm exists
if [ -e /dev/kvm ]; then
    echo "✅ /dev/kvm exists. KVM is enabled."
else
    echo "⚠️ /dev/kvm not found. Checking kernel modules..."
    
    # Check for loaded kernel modules
    if lsmod | grep -q kvm; then
        echo "✅ KVM kernel modules are loaded, but /dev/kvm is missing."
    else
        echo "❌ KVM kernel modules are not loaded."
        echo ""
        echo "👉 Trying to load KVM modules now..."

        # Try to load the appropriate module
        if grep -q vmx /proc/cpuinfo; then
            sudo modprobe kvm_intel
        elif grep -q svm /proc/cpuinfo; then
            sudo modprobe kvm_amd
        fi

        sleep 2

        if lsmod | grep -q kvm; then
            echo "✅ Modules loaded successfully."
        else
            echo "❌ Failed to load KVM modules. Possible reasons:"
            echo "   - Virtualization is disabled in BIOS/UEFI"
            echo "   - Running in a restricted environment (e.g., WSL or container)"
            echo ""
            echo "💡 Please reboot into BIOS/UEFI and enable:"
            echo "   - Intel VT-x or AMD-V"
            echo "   - SVM Mode (for AMD)"
            echo ""
            exit 1
        fi
    fi

    # Check again for /dev/kvm
    if [ -e /dev/kvm ]; then
        echo " /dev/kvm is now available. KVM is enabled!"
    else
        echo " /dev/kvm is still missing. KVM not usable."
        echo "Please make sure virtualization is enabled in your BIOS/UEFI."
        exit 1
    fi
fi

echo "🎉 KVM is fully enabled and ready to use."
# ---------- LAUNCH VM ----------
echo ""
echo "[🚀] Launching FreeBSD installer with:"
echo "    ➤ ISO: $ISO_NAME"
echo "    ➤ RAM: $RAM MB | CPUs: $CPUS | Disk: $DISK_FILE"

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
echo " ✅ QEMU booted FreeBSD installer."
echo " 💡 Tip: After install, remove ISO and reboot into disk mode."
echo "=========================================="

