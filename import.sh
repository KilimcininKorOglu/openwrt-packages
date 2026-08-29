#!/bin/bash
# Import IPK files into the feed, placing each into the matching arch directory
# (creating it if missing), then regenerate the affected indexes. Intended for use
# from CI after a project's build step.
#
# Usage: ./import.sh <file.ipk> [file2.ipk ...]
#        ./import.sh /path/to/build/*/*.ipk
#
# Arch detection: an IPK is named <pkg>_<version>_<arch>.ipk. The package name and
# version contain no underscore, while arch may (mips_24kc, aarch64_generic), so the
# arch is everything after the first two underscores, minus ".ipk". If that arch has
# no directory yet, it is created (with a .gitkeep). A "*_all.ipk" package is copied
# into every existing arch directory.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

discover_archs() {
    local d
    for d in "$SCRIPT_DIR"/*/; do
        d="${d%/}"
        echo "${d##*/}"
    done
}

if [ -z "$1" ]; then
    echo "Usage: $0 <file.ipk> [file2.ipk ...]"
    echo ""
    echo "Places each IPK into its arch directory (creating it if missing) and reindexes."
    echo "Existing architectures:"
    for a in $(discover_archs); do echo "  - $a"; done
    exit 1
fi

touched=""        # space-separated list of arch dirs that received files

mark_touched() {
    case " $touched " in
        *" $1 "*) : ;;
        *) touched="$touched $1" ;;
    esac
}

ensure_arch_dir() {
    local arch="$1"
    if [ ! -d "$SCRIPT_DIR/$arch" ]; then
        mkdir -p "$SCRIPT_DIR/$arch"
        touch "$SCRIPT_DIR/$arch/.gitkeep"
        echo "[NEW] Created arch directory: $arch"
    fi
}

for pkg in "$@"; do
    if [ ! -f "$pkg" ]; then
        echo "[WARN] Not found, skipping: $pkg"
        continue
    fi
    base=$(basename "$pkg")

    # Architecture-independent package -> every existing arch directory.
    case "$base" in
        *_all.ipk)
            for a in $(discover_archs); do
                cp "$pkg" "$SCRIPT_DIR/$a/"
                mark_touched "$a"
            done
            echo "[OK] $base -> all architectures"
            continue
            ;;
    esac

    # Parse arch: strip package name and version (first two underscore-separated
    # fields), then the .ipk suffix. e.g. pkg_1.2.3-9_mips_24kc.ipk -> mips_24kc
    stem="${base%.ipk}"
    rest="${stem#*_}"          # drop package name
    arch="${rest#*_}"          # drop version -> arch (may contain underscores)

    if [ "$arch" = "$rest" ] || [ -z "$arch" ]; then
        echo "[WARN] Cannot parse arch from: $base (expected <pkg>_<version>_<arch>.ipk)"
        continue
    fi

    ensure_arch_dir "$arch"
    cp "$pkg" "$SCRIPT_DIR/$arch/"
    mark_touched "$arch"
    echo "[OK] $base -> $arch/"
done

if [ -z "$touched" ]; then
    echo "Nothing imported."
    exit 0
fi

echo ""
echo "Regenerating indexes for:$touched"
for a in $touched; do
    "$SCRIPT_DIR/generate-index.sh" "$a"
done

echo "Done. Next: git add . && git commit -m 'Add: <package>' && git push"
