#!/bin/bash

# ============================================
# 🧠 FreeBSD QEMU Setup Script – SMART ISO SCAN
# ============================================

# ---------- CONFIGURATION ----------
DISK_FILE="freebsd.qcow2"
DISK_SIZE="20G"
RAM="4096"
CPUS="4"
BASE_URL="https://download.freebsd.org/ftp/releases/ISO-IMAGES"
ISO_DIR="isos"
mkdir -p "$ISO_DIR"
# -----------------------------------

echo "=========================================="
echo " 🔧 FreeBSD QEMU Setup"
echo "=========================================="

# ---------- TOOL CHECK ----------
REQUIRED_TOOLS=("curl" "wget" "xz" "qemu-img" "qemu-system-x86_64")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "[!] Missing: $tool (please install it)"
        exit 1
    fi
done
echo "[✔] All required tools found."
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

