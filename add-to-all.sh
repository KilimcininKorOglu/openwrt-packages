#!/bin/bash
# Add an architecture-independent IPK package to all architectures.
# Usage: ./add-to-all.sh <package_all.ipk>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Discover architecture directories automatically (see generate-index.sh).
discover_archs() {
    local d
    for d in "$SCRIPT_DIR"/*/; do
        d="${d%/}"
        echo "${d##*/}"
    done
}

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

for arch in $(discover_archs); do
    cp "$PACKAGE" "$SCRIPT_DIR/$arch/"
    echo "[OK] Copied to $arch/"
done

echo ""
echo "Done! Package added to all architectures."
echo ""
echo "Next steps:"
echo "  1. Generate indexes: ./generate-index.sh"
echo "  2. Commit: git add . && git commit -m 'Add: $PACKAGE_NAME'"
echo "  3. Push: git push"
