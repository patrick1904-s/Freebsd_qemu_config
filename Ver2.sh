#!/bin/bash

# Ensure file is given
if [[ -z "$1" ]]; then
    echo "❌ Usage: $0 <FreeBSD-XX.X-RELEASE-arch.iso>"
    exit 1
fi

ISO_FILE="$1"

# Check ISO exists
if [[ ! -f "$ISO_FILE" ]]; then
    echo "❌ File not found: $ISO_FILE"
    exit 1
fi

# Extract version and arch (e.g. 14.3, amd64)
if [[ "$ISO_FILE" =~ FreeBSD-([0-9]+\.[0-9]+)-RELEASE-([^-]+)-.*\.iso ]]; then
    VERSION="${BASH_REMATCH[1]}"
    ARCH="${BASH_REMATCH[2]}"
else
    echo "❌ Could not extract version/arch from filename."
    exit 1
fi

BASE_URL="https://download.freebsd.org/releases/ISO-IMAGES/${VERSION}"
CHECKSUM_URL="${BASE_URL}/CHECKSUM.SHA512"

echo "📦 Detected FreeBSD version: $VERSION"
echo "🌐 Fetching checksum from: $CHECKSUM_URL"

# Download checksum file
if ! wget -q "$CHECKSUM_URL" -O CHECKSUM.SHA512; then
    echo "❌ Failed to download checksum file from $CHECKSUM_URL"
    exit 1
fi

# Extract expected checksum
EXPECTED_CHECKSUM=$(grep "$ISO_FILE" CHECKSUM.SHA512 | awk '{print $1}')
if [[ -z "$EXPECTED_CHECKSUM" ]]; then
    echo "❌ Could not find checksum for $ISO_FILE"
    exit 1
fi

# Generate actual checksum
echo "🔍 Calculating SHA512 checksum..."
ACTUAL_CHECKSUM=$(sha512sum "$ISO_FILE" | awk '{print $1}')

# Compare
echo "🔐 Verifying checksum..."
if [[ "$EXPECTED_CHECKSUM" == "$ACTUAL_CHECKSUM" ]]; then
    echo "✅ Checksum verified: MATCH"
    exit 0
else
    echo "❌ Checksum mismatch!"
    echo "Expected: $EXPECTED_CHECKSUM"
    echo "Actual:   $ACTUAL_CHECKSUM"
    exit 1
fi

