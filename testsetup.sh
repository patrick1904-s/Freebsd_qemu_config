#!/usr/bin/env bash
set -euo pipefail

echo "=============================="
echo "🧠 FreeBSD QEMU Setup Script"
echo "=============================="

# ---------- CONFIGURATION ----------
DISK_FILE="freebsd.qcow2"
DISK_SIZE="20G"
RAM="4096"
CPUS="4"
BASE_URL="https://download.freebsd.org/ftp/releases/ISO-IMAGES"
ISO_DIR="isos"
mkdir -p "$ISO_DIR"

# ---------- DECLARATIVE VARIABLES ----------
REQUIRED_TOOLS=(
    curl
    wget
    xz
    qemu-img
    qemu-system-x86_64
)

# Mapping of package managers to install commands
declare -A PKG_MANAGERS=(
    [apt]="sudo apt update && sudo apt install -y"
    [dnf]="sudo dnf install -y"
    [pacman]="sudo pacman -Sy --noconfirm"
    [pkg]="sudo pkg install -y"
    [nix-env]="nix-env -iA nixpkgs"
)

# ---------- FUNCTIONS ----------
check_dependencies() {
    echo "🔍 Checking for required tools..."
    MISSING_TOOLS=()

    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            MISSING_TOOLS+=("$tool")
        fi
    done

    if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
        echo "✅ All dependencies are installed."
        return 0
    fi

    echo "⚠️ Missing: ${MISSING_TOOLS[*]}"
    install_dependencies "${MISSING_TOOLS[@]}"
}

install_dependencies() {
    local missing_tools=("$@")

    echo -n "🌐 Checking internet... "
    if ping -c 1 google.com &>/dev/null; then
        echo "connected."
    else
        echo "❌ No internet connection. Please install manually: ${missing_tools[*]}"
        exit 1
    fi

    local pkg_found=false
    for manager in "${!PKG_MANAGERS[@]}"; do
        if command -v "$manager" &>/dev/null; then
            echo "📦 Installing missing packages using $manager..."
            ${PKG_MANAGERS[$manager]} "${missing_tools[@]}"
            pkg_found=true
            break
        fi
    done

    if ! $pkg_found; then
        echo "❌ No supported package manager found."
        echo "🛠️ Please install manually: ${missing_tools[*]}"
        exit 1
    fi
}

customize_resources() {
    echo ""
    echo " Default Resources:"
    echo "    ➤ CPUs : $CPUS"
    echo "    ➤ RAM  : $RAM MB"
    echo "    ➤ Disk : $DISK_SIZE"

    read -p "✨ Customize CPU/RAM/Disk? (y/N): " CUSTOMIZE
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
}

check_kvm() {
    echo "🔍 Checking KVM support..."

    if grep -E -q '(vmx|svm)' /proc/cpuinfo; then
        echo "✅ CPU supports virtualization."
    else
        echo "❌ No virtualization support detected. Exiting."
        exit 1
    fi

    if [ ! -e /dev/kvm ]; then
        echo "⚠️ /dev/kvm not found. Attempting to load kernel modules..."
        if grep -q vmx /proc/cpuinfo; then
            sudo modprobe kvm_intel || true
        elif grep -q svm /proc/cpuinfo; then
            sudo modprobe kvm_amd || true
        fi
    fi

    if [ -e /dev/kvm ]; then
        echo "✅ KVM is enabled."
    else
        echo "❌ KVM not available. Enable in BIOS/UEFI."
        exit 1
    fi
}

# ---------- MAIN WORKFLOW ----------
customize_resources
check_dependencies
check_kvm

echo "✅ Environment ready. Continue with ISO download & QEMU setup..."
# (Rest of your ISO download and VM launch logic would follow here)
