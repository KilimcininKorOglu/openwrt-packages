# Adding a Project to the Shared Feed

How to make any OpenWRT project publish its release IPKs to this shared feed
automatically. Follow the steps in order; nothing runs from your local machine.

## How it works

```
project: git tag v1.2.3
   -> release.yml   build IPKs, create GitHub Release, send repository_dispatch
        -> openwrt-packages/feed-update.yml
             gh release download the IPKs -> import.sh -> commit + push to the feed
```

The device then installs from `https://raw.githubusercontent.com/KilimcininKorOglu/openwrt-packages/master/<ARCH>`.

## Prerequisites

- The project's `build.sh` produces OpenWRT `.ipk` packages.
- The project repo lives under the `KilimcininKorOglu` GitHub org and is **public**
  (the feed downloads release assets cross-repo with the default token).
- `gh` CLI is installed and authenticated for the secret step.

## Step 1 — IPK naming and version override in build.sh

The feed routes each IPK by its filename, so it must be
`<pkg>_<version>_<arch>.ipk` where `<arch>` is the real OpenWRT architecture
(`mips_24kc`, `mipsel_24kc`, `aarch64_generic`, `arm_cortex-a7`, `x86_64`, ...).
The package name and version must not contain underscores.

Let CI pass the tag as the version by making `PKG_VERSION` overridable:

```sh
PKG_VERSION="${PKG_VERSION:-0.1.0}"   # CI passes the tag; local build uses the default
```

If the version is also injected into the binary, do it via an ldflag from
`PKG_VERSION` (`-X main.Version=${PKG_VERSION}`) rather than hardcoding it twice.

## Step 2 — Add .github/workflows/ci.yml

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
permissions:
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    env:
      CGO_ENABLED: "0"
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.26.x"
      - run: go vet ./...
      - run: go build ./...
      - run: go build -tags openwrt ./...
      - run: go test ./...
```

Adjust the toolchain steps to the project's language if it is not Go.

## Step 3 — Add .github/workflows/release.yml

The dispatch step reads the repo name automatically, so this file is identical
across projects — no per-project edits.

```yaml
name: Release
on:
  push:
    tags: ["v*"]
permissions:
  contents: write
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0            # build.sh derives PKG_RELEASE from commit count
      - uses: actions/setup-go@v5
        with:
          go-version: "1.26.x"
      - name: Build all platforms and IPKs
        run: |
          set -euo pipefail
          VERSION="${GITHUB_REF_NAME#v}"
          echo "VERSION=$VERSION" >> "$GITHUB_ENV"
          PKG_VERSION="$VERSION" bash build.sh
      - name: Publish GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            build/${{ env.VERSION }}-*/*
      - name: Notify shared feed repository
        env:
          GH_TOKEN: ${{ secrets.FEED_DISPATCH_TOKEN }}
          REPO: ${{ github.event.repository.name }}
          TAG: ${{ github.ref_name }}
        run: |
          set -euo pipefail
          jq -nc --arg repo "$REPO" --arg tag "$TAG" \
            '{event_type:"publish-ipk",client_payload:{repo:$repo,tag:$tag}}' \
          | gh api --method POST \
              repos/KilimcininKorOglu/openwrt-packages/dispatches --input -
```

Match `build/${{ env.VERSION }}-*/*` to where the project's `build.sh` writes its
output, if different.

## Step 4 — Add the FEED_DISPATCH_TOKEN secret

Cross-repo `repository_dispatch` cannot use the built-in `GITHUB_TOKEN`, so a PAT
is required. You can reuse the same PAT across every project.

1. Create a fine-grained PAT (github.com/settings/tokens): resource owner
   `KilimcininKorOglu`, access limited to `openwrt-packages`, permission
   `Contents: Read and write`.
2. Add it as a secret on the new project (enter the value when prompted):

```sh
gh secret set FEED_DISPATCH_TOKEN --repo KilimcininKorOglu/<project>
```

## Step 5 — (optional) version-update skill

To bump the version, changelog, tag, and push with one command, create a
project-local `version-update` skill (see the `version-update-skill-creator`).

## Step 6 — Release and verify

```sh
git tag v0.1.0
git push origin v0.1.0
```

- `release.yml` builds, publishes the GitHub Release, and dispatches to the feed.
- `feed-update.yml` downloads the IPKs and runs `import.sh`.
- `import.sh` creates any missing arch directory automatically, so a brand-new
  architecture needs no manual setup here.
- Check the feed repo's Actions tab and confirm a `feed: <project> v0.1.0` commit.

## Feed-side changes

None are needed for a project under `KilimcininKorOglu` — `feed-update.yml` takes
the repo name from the dispatch payload and `import.sh` creates arch dirs on
demand. Only if a project lives under a **different owner**, update the hardcoded
`KilimcininKorOglu/$REPO` in `feed-update.yml` (and ensure that repo is reachable
by the token used for `gh release download`).

## Device usage

```sh
echo "src/gz custom_repo https://raw.githubusercontent.com/KilimcininKorOglu/openwrt-packages/master/<ARCH>" >> /etc/opkg/customfeeds.conf
opkg update
opkg install <package>
```
