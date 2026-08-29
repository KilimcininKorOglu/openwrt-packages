#!/bin/bash
# Import IPK files into the feed, placing each into the matching arch directory,
# then regenerate the affected indexes. Intended for use from any OpenWRT project
# after its build step.
#
# Usage: ./import.sh <file.ipk> [file2.ipk ...]
#        ./import.sh /path/to/build/*/*.ipk
#
# Arch detection: an IPK is named <pkg>_<version>_<arch>.ipk. Because arch names
# contain underscores (mips_24kc, aarch64_generic), the arch is matched against
# the existing arch directories by the "_<arch>.ipk" suffix, not by splitting on
# "_". A "*_all.ipk" package is copied into every arch directory.

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
    echo "Places each IPK into its matching arch directory and regenerates indexes."
    echo "Known architectures:"
    for a in $(discover_archs); do echo "  - $a"; done
    exit 1
fi

ARCHS=$(discover_archs)
touched=""        # space-separated list of arch dirs that received files
unmatched=0

mark_touched() {
    case " $touched " in
        *" $1 "*) : ;;
        *) touched="$touched $1" ;;
    esac
}

for pkg in "$@"; do
    if [ ! -f "$pkg" ]; then
        echo "[WARN] Not found, skipping: $pkg"
        continue
    fi
    base=$(basename "$pkg")

    # Architecture-independent package -> all arch directories.
    case "$base" in
        *_all.ipk)
            for a in $ARCHS; do
                cp "$pkg" "$SCRIPT_DIR/$a/"
                mark_touched "$a"
            done
            echo "[OK] $base -> all architectures"
            continue
            ;;
    esac

    # Match against the longest known arch suffix.
    matched=""
    for a in $ARCHS; do
        case "$base" in
            *_"$a".ipk)
                if [ ${#a} -gt ${#matched} ]; then matched="$a"; fi
                ;;
        esac
    done

    if [ -n "$matched" ]; then
        cp "$pkg" "$SCRIPT_DIR/$matched/"
        mark_touched "$matched"
        echo "[OK] $base -> $matched/"
    else
        echo "[WARN] No matching arch directory for: $base"
        echo "       Create the arch directory first, then re-run."
        unmatched=1
    fi
done

if [ -z "$touched" ]; then
    echo "Nothing imported."
    exit $unmatched
fi

echo ""
echo "Regenerating indexes for:$touched"
for a in $touched; do
    "$SCRIPT_DIR/generate-index.sh" "$a"
done

echo "Done. Next: git add . && git commit -m 'Add: <package>' && git push"
exit $unmatched
