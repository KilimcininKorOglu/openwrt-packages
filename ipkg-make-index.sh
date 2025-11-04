#!/bin/bash
set -e

pkg_dir=$1

if [ -z "$pkg_dir" ] || [ ! -d "$pkg_dir" ]; then
    echo "Usage: ipkg-make-index <package_directory>" >&2
    exit 1
fi

empty=1

for pkg in $(find "$pkg_dir" -name '*.ipk' | sort); do
    empty=
    name="${pkg##*/}"
    name="${name%%_*}"
    [[ "$name" = "kernel" ]] && continue
    [[ "$name" = "libc" ]] && continue

    echo "Processing: $name" >&2

    filename=$(basename "$pkg")
    file_size=$(stat -L -c%s "$pkg")
    sha256sum=$(sha256sum "$pkg" | cut -d ' ' -f 1)

    # Extract control file
    control_file=$(mktemp)
    tar -xzOf "$pkg" ./control.tar.gz | tar -xzOf - ./control > "$control_file"

    # Output control info with filename, size, and checksum
    cat "$control_file"
    echo "Filename: $filename"
    echo "Size: $file_size"
    echo "SHA256sum: $sha256sum"
    echo ""

    rm "$control_file"
done

[ -n "$empty" ] && echo
exit 0
