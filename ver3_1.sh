#!/bin/bash

set -euo pipefail

# 🧠 Function: Print error and exit
die() {
    echo "❌ $1" >&2
    exit 1
}

# 🧠 Usage help
usage() {
    echo "Usage: $0 <FreeBSD-XX.X-RELEASE-arch-*.iso>"
    exit 1
}

# 📥 Input validation
if [[ $# -ne 1 ]]; then
    usage
fi

ISO_FILE="$1"

if [[ ! -f "$ISO_FILE" ]]; then
    die "File not found: $ISO_FILE"
fi

# 🧠 Extract version and arch using regex
if [[ "$ISO_FILE" =~ FreeBSD-([0-9]+\.[0-9]+)-RELEASE-([^-]+)-.*\.iso ]]; then
    VERSION="${BASH_REMATCH[1]}"
    ARCH="${BASH_REMATCH[2]}"
else
    die "Filename format incorrect. Could not extract version and architecture."
fi

BASE_URL="https://download.freebsd.org/releases/ISO-IMAGES/${VERSION}"
CHECKSUM_FILE="CHECKSUM.SHA512"
CHECKSUM_URL="${BASE_URL}/${CHECKSUM_FILE}"

echo "📦 FreeBSD Version: $VERSION"
echo "🖥️ Architecture: $ARCH"
echo "🌐 Downloading checksum from: $CHECKSUM_URL"

# 🔽 Download checksum file
if ! wget -q "$CHECKSUM_URL" -O "$CHECKSUM_FILE"; then
    die "Failed to download checksum file."
fi

# 📜 Find all checksums matching this ISO file (in case of suffix differences)
echo "🔍 Searching checksum file for: $ISO_FILE"
EXPECTED_CHECKSUM=""
FILENAME=$(basename "$ISO_FILE")

while IFS= read -r line; do
    # Expected format: SHA512 (filename) = checksum
    if [[ "$line" =~ ^SHA512\ \(([^)]+)\)\ =\ ([a-fA-F0-9]{128})$ ]]; then
        FILE_IN_CHECKSUM="${BASH_REMATCH[1]}"
        CHECKSUM_VALUE="${BASH_REMATCH[2]}"

        if [[ "$FILE_IN_CHECKSUM" == "$FILENAME" ]]; then
            EXPECTED_CHECKSUM="$CHECKSUM_VALUE"
            break
        fi
    fi
done < "$CHECKSUM_FILE"

if [[ -z "$EXPECTED_CHECKSUM" ]]; then
    die "Checksum entry for $FILENAME not found in $CHECKSUM_FILE"
fi

# 🔐 Calculate actual checksum
echo "🔧 Calculating local SHA512 checksum..."
ACTUAL_CHECKSUM=$(sha512sum "$ISO_FILE" | awk '{print $1}')

# ✅ Compare
echo "🔐 Comparing checksums..."
if [[ "$EXPECTED_CHECKSUM" == "$ACTUAL_CHECKSUM" ]]; then
    echo "✅ Checksum verified successfully!"
    exit 0
else
    echo "❌ Checksum mismatch!"
    echo "Expected: $EXPECTED_CHECKSUM"
    echo "Actual:   $ACTUAL_CHECKSUM"
    exit 1
fi

