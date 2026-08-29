# OpenWRT Custom Package Repository

A shared opkg package feed for OpenWRT devices, hosted on GitHub and served over
raw URLs. It is package-agnostic: any OpenWRT project can drop its `.ipk` files
here, regenerate the index, and push. Packages are organized by CPU architecture.

Repository: `https://github.com/KilimcininKorOglu/openwrt-packages` (branch `master`).

## Installation on an OpenWRT Device

### 1. Add the feed

SSH into the device and add the line for your architecture:

```sh
echo "src/gz custom_repo https://raw.githubusercontent.com/KilimcininKorOglu/openwrt-packages/master/<ARCH>" >> /etc/opkg/customfeeds.conf
```

Replace `<ARCH>` with your device architecture (see below).

### 2. Update package lists

```sh
opkg update
```

### 3. Install a package

```sh
opkg install <PACKAGE_NAME>
```

## Supported Architectures

- `aarch64_generic` - ARM 64-bit
- `arm_cortex-a7` - ARM Cortex-A7
- `arm_cortex-a9` - ARM Cortex-A9
- `mips_24kc` - MIPS big-endian (e.g. GL-XE300, ath79/ramips-be routers)
- `mipsel_24kc` - MIPS little-endian
- `x86_64` - x86 64-bit

Find your device architecture:

```sh
opkg print-architecture
```

Adding a new architecture is just creating a directory; the scripts discover
arch directories automatically, so no script edits are needed.

```sh
mkdir arm_cortex-a15
```

## Maintainer Guide

No external tools are required. The scripts run on Linux and macOS (GNU or BSD
`stat`/`sha256sum`/`shasum` are both handled).

### Add packages and publish

The simplest path is `import.sh`, which routes each IPK to the correct arch
directory (by the `_<arch>.ipk` suffix), fans `*_all.ipk` out to every arch, and
regenerates only the affected indexes:

```sh
./import.sh /path/to/build/*/*.ipk
git add .
git commit -m "Add: <package>"
git push
```

### Manual alternative

```sh
# Copy an IPK into a specific architecture, then index that arch
cp your-package_1.0_mips_24kc.ipk mips_24kc/
./generate-index.sh mips_24kc

# Architecture-independent package -> all architectures
./add-to-all.sh your-package_1.0_all.ipk
./generate-index.sh            # regenerate every arch index
```

Each run writes `Packages` (metadata) and `Packages.gz` (compressed) into the
arch directory. Both files MUST be committed, because opkg fetches them over the
raw URL.

## Using this feed from another project

For the full automated setup (CI + Release + auto-push to this feed), see
[INTEGRATION.md](INTEGRATION.md).

To import IPKs manually into a local checkout of this repository instead, e.g.
from a sibling project in the same parent folder:

```sh
../openwrt-packages/import.sh build/<version>/*.ipk
( cd ../openwrt-packages && git add . && git commit -m "Add: <project> <version>" && git push )
```

The IPK filename must end with `_<arch>.ipk` where `<arch>` matches an arch
directory (or `_all.ipk` for architecture-independent packages).

## Repository Structure

```
.
├── aarch64_generic/          # ARM 64-bit packages + Packages index
├── arm_cortex-a7/            # ARM Cortex-A7 packages + Packages index
├── arm_cortex-a9/            # ARM Cortex-A9 packages + Packages index
├── mips_24kc/                # MIPS big-endian packages + Packages index
├── mipsel_24kc/              # MIPS little-endian packages + Packages index
├── x86_64/                   # x86 64-bit packages + Packages index
├── import.sh                 # Route IPKs to arch dirs and reindex (main entry)
├── add-to-all.sh             # Copy an arch-independent IPK to all dirs
├── generate-index.sh         # Regenerate indexes (all or a single arch)
└── ipkg-make-index.sh        # Extract IPK metadata (called by generate-index.sh)
```

Each architecture directory keeps a `.gitkeep` so the structure is tracked even
when empty. Once packages are added it also holds `.ipk`, `Packages`, and
`Packages.gz`.

## How It Works

1. `import.sh` (or `generate-index.sh`) is the command you run.
2. `ipkg-make-index.sh` reads each IPK's `control.tar.gz` and emits its metadata
   plus `Filename`, `Size`, and `SHA256sum`.
3. The collected metadata becomes `Packages`, compressed to `Packages.gz`.
4. opkg on the device reads `Packages.gz` from the raw URL.

## Notes

- Each architecture folder is independent; indexes are architecture-specific.
- No external dependencies; works on Linux and macOS.
- Arch directories are discovered automatically from the top-level folders.

## License

Individual packages may carry their own licenses. Check each package's documentation.
