#!/usr/bin/env bash
set -euo pipefail

# Input: local ISO filename
ISO="$1"
if [[ -z "$ISO" || ! -f "$ISO" ]]; then
  echo "Usage: $0 FreeBSD-XX.X-RELEASE-arch-disc1.iso" && exit 1
fi

# Parse version & arch
if [[ "$ISO" =~ FreeBSD-([0-9]+\.[0-9]+)-RELEASE-([^-]+)-.+\.iso ]]; then
  VERSION="${BASH_REMATCH[1]}"
  ARCH="${BASH_REMATCH[2]}"
else
  echo "Cannot parse version/arch from ISO name"; exit 1
fi

# Fetch available versions from upstream directory
LIST=$(wget -qO- https://download.freebsd.org/releases/ISO-IMAGES/ \
       | grep -oP 'href="\K[0-9]+\.[0-9]+(?=/")' | sort -V)
if ! grep -qx "$VERSION" <<<"$LIST"; then
  echo "Version $VERSION not found in remote directory"; exit 1
fi

URL="https://download.freebsd.org/releases/ISO-IMAGES/${VERSION}"
echo "Using version: $VERSION  arch: $ARCH"
echo "Fetching checksum directory: $URL" >&2

# Choose checksum type (prefer SHA512)
CHECKSUM_FILE=$(wget -qO- "$URL/" \
                | grep -oP 'CHECKSUM\.SHA(512|256)-FreeBSD-'"$VERSION"'-RELEASE-'"$ARCH"'')
if [[ -z "$CHECKSUM_FILE" ]]; then
  echo "No checksum file for version/arch"; exit 1
fi

CHK_URL="$URL/$CHECKSUM_FILE"
echo "Downloading checksum: $CHK_URL" >&2
wget -q "$CHK_URL" -O "$CHECKSUM_FILE" || exit 1

# Extract expected hash
EXPECTED=$(grep "$(basename "$ISO")" "$CHECKSUM_FILE" | awk '{print $1}')
if [[ -z "$EXPECTED" ]]; then
  echo "Checksum entry not found in $CHECKSUM_FILE"; exit 1
fi

# Compute local hash
ALG=$(echo "$CHECKSUM_FILE" | awk -F. '{print (index($1,"SHA512") ? "sha512sum" : "sha256sum")}')
echo "Computing $ALG ..." >&2
ACTUAL=$($ALG "$ISO" | awk '{print $1}')

echo; echo "Expected: $EXPECTED"
echo "Actual:   $ACTUAL"
if [[ "$EXPECTED" == "$ACTUAL" ]]; then
  echo "✅ Checksum match!"
  exit 0
else
  echo "❌ Checksum mismatch!"
  exit 1
fi


