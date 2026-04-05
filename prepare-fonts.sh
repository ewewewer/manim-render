#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$SCRIPT_DIR/macfonts"
FONTS_DIR="$SCRIPT_DIR/fonts"

rm -rf "$TEMP_DIR"
mkdir -p "$FONTS_DIR"

git clone --depth 1 https://github.com/fefelixa/macfonts "$TEMP_DIR"

find "$TEMP_DIR" \( -path "*/SF Pro Display/*.otf" -o -path "*/SF Pro Text/*.otf" -o -path "*/San Francisco/*.otf" \) -type f -exec cp {} "$FONTS_DIR"/ \;

rm -rf "$TEMP_DIR"

echo "Fonts copied into $FONTS_DIR"
