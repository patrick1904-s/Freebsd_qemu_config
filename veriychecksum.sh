#!/bin/bash

# Usage: ./verify_checksum.sh <file> <checksum_url> <SHA256|SHA512>
# Example: ./verify_checksum.sh FreeBSD.iso https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/14.1/CHECKSUM.SHA512 SHA512

set -e

FILE="$1"
CHECKSUM_URL="$2"
ALGO="${3:-SHA512}"  # Default to SHA512

if [[ -z "$FILE" || -z "$CHECKSUM_URL" ]]; then
    echo "❌ Usage: $0 <file> <checksum_url> <SHA256|SHA512>"
    exit 1
fi

# Step 1: Download checksum file
echo "📥 Downloading checksum file from: $CHECKSUM_URL"
CHECKSUM_FILE=$(basename "$CHECKSUM_URL")

if ! wget -q "$CHECKSUM_URL" -O "$CHECKSUM_FILE"; then
    echo "❌ Failed to download checksum file."
    exit 1
fi

# Step 2: Extract expected checksum
EXPECTED_CHECKSUM=$(grep "$FILE" "$CHECKSUM_FILE" | awk '{print $1}')

if [[ -z "$EXPECTED_CHECKSUM" ]]; then
    echo "❌ Could not find checksum for '$FILE' in '$CHECKSUM_FILE'"
    exit 1
fi

# Step 3: Generate actual checksum
echo "🔍 Generating $ALGO hash for $FILE..."
if [[ "$ALGO" == "SHA256" ]]; then
    ACTUAL_CHECKSUM=$(sha256sum "$FILE" | awk '{print $1}')
elif [[ "$ALGO" == "SHA512" ]]; then
    ACTUAL_CHECKSUM=$(sha512sum "$FILE" | awk '{print $1}')
else
    echo "❌ Unsupported algorithm: $ALGO"
    exit 1
fi

# Step 4: Compare the checksums
echo "🔐 Verifying checksum..."
if [[ "$ACTUAL_CHECKSUM" == "$EXPECTED_CHECKSUM" ]]; then
    echo "✅ Checksum verified: Match"
    exit 0
else
    echo "❌ Checksum mismatch!"
    echo "Expected: $EXPECTED_CHECKSUM"
    echo "Actual:   $ACTUAL_CHECKSUM"
    exit 1
fi

