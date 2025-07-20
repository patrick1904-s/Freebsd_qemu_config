# Set ISO_DIR if not already set
ISO_DIR="${ISO_DIR:-./isos}"

# Ensure ISO_DIR exists
mkdir -p "$ISO_DIR"

CHECKSUM_URL="$BASE_URL/${VERSION}/CHECKSUM.SHA512"
CHECKSUM_FILE="${ISO_DIR}/CHECKSUM.SHA512"

read -p "🔐 Would you like to verify the ISO checksum? (y/N): " VERIFY_CHECKSUM
VERIFY_CHECKSUM=${VERIFY_CHECKSUM,,}

if [[ "$VERIFY_CHECKSUM" == "y" ]]; then
    echo "[*] Downloading checksum file..."
    wget -q -O "$CHECKSUM_FILE" "$CHECKSUM_URL"

    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to download checksum file."
    else
        echo "[*] Verifying checksum..."
        pushd "$ISO_DIR" > /dev/null

        ISO_XZ=$(basename "$ISO_URL")
        EXPECTED_HASH=$(grep "${ISO_XZ}" CHECKSUM.SHA512 | awk '{print $4}')
        ACTUAL_HASH=$(sha512sum "$ISO_XZ" | awk '{print $1}')

        if [[ "$EXPECTED_HASH" == "$ACTUAL_HASH" ]]; then
            echo "✅ Checksum matched. File is authentic."
        else
            echo "❌ Checksum mismatch!"
            echo "⚠️ The downloaded ISO may be corrupted or tampered with."
            read -p "❓ Do you want to continue anyway? (y/N): " CONTINUE_ANYWAY
            CONTINUE_ANYWAY=${CONTINUE_ANYWAY,,}
            if [[ "$CONTINUE_ANYWAY" != "y" ]]; then
                echo "🛑 Aborting due to checksum mismatch."
                exit 1
            fi
        fi

        popd > /dev/null
    fi
else
    echo "⚠️ Skipped checksum verification by user choice."
fi

