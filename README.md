# OpenWRT Custom Package Repository

Custom IPK package repository for OpenWRT devices, hosted on GitHub.

## 📦 Installation on OpenWRT Device

### 1. Add Repository

SSH into your OpenWRT device and run:

```sh
echo "src/gz custom_repo https://raw.githubusercontent.com/USERNAME/REPO_NAME/main/ARCHITECTURE" >> /etc/opkg/customfeeds.conf
```

**Replace:**

- `USERNAME` - Your GitHub username
- `REPO_NAME` - Repository name
- `ARCHITECTURE` - Your device architecture (see below)

### 2. Update Package Lists

```sh
opkg update
```

### 3. Install Package

```sh
opkg install PACKAGE_NAME
```

## 🏗️ Supported Architectures

- `aarch64_generic` - ARM 64-bit
- `arm_cortex-a7` - ARM Cortex-A7
- `arm_cortex-a9` - ARM Cortex-A9
- `mipsel_24kc` - MIPS
- `x86_64` - x86 64-bit

**Find your device architecture:**

```sh
opkg print-architecture
```

## 🔧 Maintainer Guide

### Initial Setup

No additional tools needed! Everything is included in this repository.

### Adding Packages

**1. Copy IPK files to architecture folder:**

```sh
cp your-package.ipk aarch64_generic/
```

**2. Generate package index:**

```sh
# For all architectures (automatically processes all)
./generate-index.sh

# Or for specific architecture only
./generate-index.sh aarch64_generic
```

This will create:

- `Packages` - Package metadata
- `Packages.gz` - Compressed index

**3. Commit and push:**

```sh
git add .
git commit -m "Add: your-package"
git push
```

### Example Workflows

**Single architecture:**

```sh
# Add packages to specific architecture
cp package1.ipk package2.ipk aarch64_generic/

# Generate index for that architecture
./generate-index.sh aarch64_generic

# Push to GitHub
git add .
git commit -m "Add packages: package1, package2"
git push
```

**Multiple architectures:**

```sh
# Add packages to different architectures
cp package-arm64.ipk aarch64_generic/
cp package-mips.ipk mipsel_24kc/
cp package-x86.ipk x86_64/

# Generate indexes for ALL architectures at once
./generate-index.sh

# Push to GitHub
git add .
git commit -m "Add multi-arch packages"
git push
```

**Architecture-independent package (works on all):**

```sh
# Add architecture-independent package to all architectures
./add-to-all.sh my-package_1.0_all.ipk

# Generate indexes for all architectures
./generate-index.sh

# Push to GitHub
git add .
git commit -m "Add: my-package (all architectures)"
git push
```

## 📁 Repository Structure

```
.
├── aarch64_generic/          # ARM 64-bit packages
│   ├── package1.ipk
│   ├── package2.ipk
│   ├── Packages              # Generated index
│   └── Packages.gz           # Compressed index
├── arm_cortex-a7/            # ARM Cortex-A7 packages
├── arm_cortex-a9/            # ARM Cortex-A9 packages
├── mipsel_24kc/              # MIPS packages
├── x86_64/                   # x86 64-bit packages
├── generate-index.sh         # Main script
└── ipkg-make-index.sh        # Index generator (auto-called)
```

## 🛠️ How It Works

1. `generate-index.sh` - Main script you run
2. `ipkg-make-index.sh` - Extracts metadata from IPK files
3. Creates `Packages` file with package info (name, version, dependencies, etc.)
4. Compresses to `Packages.gz` for opkg

## 📝 Notes

- Each architecture folder is independent
- Package indexes are architecture-specific
- No external dependencies required
- Works on any Linux system (Ubuntu, Debian, etc.)

## 📄 License

Individual packages may have their own licenses. Check package documentation.
