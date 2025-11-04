#!/bin/bash
# Add IPK package to all architectures
# Usage: ./add-to-all.sh <package.ipk>

set -e

ARCHITECTURES=("aarch64_generic" "arm_cortex-a7" "arm_cortex-a9" "mipsel_24kc" "x86_64")

if [ -z "$1" ]; then
    echo "Usage: $0 <package.ipk>"
    echo ""
    echo "This will copy the IPK to all architecture directories."
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: File '$1' not found"
    exit 1
fi

PACKAGE="$1"
PACKAGE_NAME=$(basename "$PACKAGE")

echo "Adding $PACKAGE_NAME to all architectures..."
echo ""

for arch in "${ARCHITECTURES[@]}"; do
    if [ -d "$arch" ]; then
        cp "$PACKAGE" "$arch/"
        echo "✓ Copied to $arch/"
    else
        echo "⚠ Skipped $arch/ (directory not found)"
    fi
done

echo ""
echo "Done! Package added to all architectures."
echo ""
echo "Next steps:"
echo "  1. Generate indexes: ./generate-index.sh"
echo "  2. Commit: git add . && git commit -m 'Add: $PACKAGE_NAME'"
echo "  3. Push: git push"
