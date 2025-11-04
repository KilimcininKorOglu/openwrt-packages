#!/bin/bash
# Generate OpenWRT package index
# Usage: ./generate-index.sh [architecture_dir]
#        ./generate-index.sh              (process all architectures)
#        ./generate-index.sh aarch64_generic   (process specific arch)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHITECTURES=("aarch64_generic" "arm_cortex-a7" "arm_cortex-a9" "mipsel_24kc" "x86_64")

generate_for_arch() {
    local arch_dir="$1"

    # Check for IPK files
    if ! ls "$arch_dir"/*.ipk >/dev/null 2>&1; then
        echo "⊘ Skipping $arch_dir (no .ipk files)"
        return 0
    fi

    echo "→ Generating index for $arch_dir..."

    # Generate Packages file using our local ipkg-make-index.sh
    "$SCRIPT_DIR/ipkg-make-index.sh" "$arch_dir" > "$arch_dir/Packages"

    # Create compressed version
    gzip -9fc "$arch_dir/Packages" > "$arch_dir/Packages.gz"

    echo "✓ Generated: Packages, Packages.gz"
    ls -lh "$arch_dir/Packages" "$arch_dir/Packages.gz" | awk '{print "  " $9, "-", $5}'
    echo ""
}

# If argument provided, process only that architecture
if [ -n "$1" ]; then
    if [ ! -d "$1" ]; then
        echo "Error: Directory '$1' not found"
        echo ""
        echo "Usage: $0 [architecture_directory]"
        echo "Available architectures:"
        for arch in "${ARCHITECTURES[@]}"; do
            echo "  - $arch"
        done
        exit 1
    fi
    generate_for_arch "$1"
else
    # No argument, process all architectures
    echo "Processing all architectures..."
    echo ""
    for arch in "${ARCHITECTURES[@]}"; do
        if [ -d "$arch" ]; then
            generate_for_arch "$arch"
        fi
    done
    echo "Done!"
fi
