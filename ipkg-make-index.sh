#!/bin/bash
set -e

pkg_dir=$1

if [ -z "$pkg_dir" ] || [ ! -d "$pkg_dir" ]; then
    echo "Usage: ipkg-make-index <package_directory>" >&2
    exit 1
fi

# Portable helpers: GNU coreutils on Linux, BSD tools on macOS.
file_size() {
    stat -L -c%s "$1" 2>/dev/null || stat -f%z "$1"
}
file_sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d ' ' -f 1
    else
        shasum -a 256 "$1" | cut -d ' ' -f 1
    fi
}

empty=1

for pkg in $(find "$pkg_dir" -name '*.ipk' | sort); do
    empty=
    name="${pkg##*/}"
    name="${name%%_*}"
    [[ "$name" = "kernel" ]] && continue
    [[ "$name" = "libc" ]] && continue

    echo "Processing: $name" >&2

    filename=$(basename "$pkg")
    file_sz=$(file_size "$pkg")
    sha256=$(file_sha256 "$pkg")

    # Extract control file
    control_file=$(mktemp)
    tar -xzOf "$pkg" ./control.tar.gz | tar -xzOf - ./control > "$control_file"

    # Output control info with filename, size, and checksum
    cat "$control_file"
    echo "Filename: $filename"
    echo "Size: $file_sz"
    echo "SHA256sum: $sha256"
    echo ""

    rm "$control_file"
done

[ -n "$empty" ] && echo
exit 0
