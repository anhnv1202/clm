#!/bin/sh
# clm installer - downloads prebuilt binary from GitHub Releases
# Works on Linux, macOS, WSL, Git Bash (Windows)
# Usage: curl -fsSL https://raw.githubusercontent.com/anhnv1202/clm/main/install.sh | sh

set -e

REPO="anhnv1202/clm"
GITHUB_API="https://api.github.com/repos/${REPO}"

# ── Detect platform ──────────────────────────────────────────────
case "$(uname -s)" in
    Darwin)  os="macos" ;;
    Linux)   os="linux" ;;
    MINGW*|MSYS*|CYGWIN*) os="windows" ;;
    *)       echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
    x86_64|amd64)  arch="x64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)             echo "Unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

# macOS Rosetta: prefer native arm64
if [ "$os" = "macos" ] && [ "$arch" = "x64" ]; then
    if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = "1" ]; then
        arch="arm64"
    fi
fi

platform="${os}-${arch}"

echo "Platform: $platform"

# ── Find downloader ──────────────────────────────────────────────
if command -v curl >/dev/null 2>&1; then
    dl() { curl -fsSL -o "$1" "$2"; }
    dl_s() { curl -fsSL "$1"; }
elif command -v wget >/dev/null 2>&1; then
    dl() { wget -q -O "$1" "$2"; }
    dl_s() { wget -q -O - "$1"; }
else
    echo "Error: curl or wget required" >&2; exit 1
fi

# ── Get latest release ───────────────────────────────────────────
echo "Fetching latest release..."

# Try GitHub API first, fall back to latest redirect
latest_tag=$(dl_s "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep '"tag_name"' | head -1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -z "$latest_tag" ]; then
    latest_tag=$(dl_s "https://github.com/${REPO}/releases/latest" 2>/dev/null | grep -o 'tag/[^"]*' | head -1 | sed 's/tag\///')
fi

if [ -z "$latest_tag" ]; then
    echo "Error: Could not find latest release. Is there a published release?" >&2
    echo "Create one: git tag v1.0.0 && git push origin v1.0.0" >&2
    exit 1
fi

echo "Latest: $latest_tag"

# ── Download binary ──────────────────────────────────────────────
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${latest_tag}/clm-${platform}"

# Windows has .exe
if [ "$os" = "windows" ]; then
    DOWNLOAD_URL="${DOWNLOAD_URL}.exe"
fi

BIN_DIR="${HOME}/.local/bin"
DEST="${BIN_DIR}/clm"

mkdir -p "$BIN_DIR"

echo "Downloading clm-${platform}..."

set +e
dl "$DEST" "$DOWNLOAD_URL"
dl_status=$?
set -e

if [ "$dl_status" -ne 0 ]; then
    echo ""
    if [ "$dl_status" -eq 23 ]; then
        echo "Error: Download failed while writing to ${DEST}." >&2
        echo "Check disk space and write permission for ${BIN_DIR}." >&2
    elif [ "$dl_status" -eq 22 ] || [ "$dl_status" -eq 8 ]; then
        echo "Error: Binary for $platform not found on release ${latest_tag}." >&2
        echo "Available platforms may differ. Check:" >&2
        echo "  https://github.com/${REPO}/releases/${latest_tag}" >&2
    else
        echo "Error: Download failed (code: $dl_status)." >&2
        echo "URL: ${DOWNLOAD_URL}" >&2
    fi
    exit 1
fi

chmod +x "$DEST"

# ── Verify ───────────────────────────────────────────────────────
CHECKSUM_URL="https://github.com/${REPO}/releases/download/${latest_tag}/checksums.txt"
checksum_file=$(mktemp)
if dl "$checksum_file" "$CHECKSUM_URL" 2>/dev/null; then
    expected=$(grep "clm-${platform}" "$checksum_file" | awk '{print $1}')
    if [ -n "$expected" ]; then
        if command -v sha256sum >/dev/null 2>&1; then
            actual=$(sha256sum "$DEST" | awk '{print $1}')
        elif command -v shasum >/dev/null 2>&1; then
            actual=$(shasum -a 256 "$DEST" | awk '{print $1}')
        else
            actual=""
        fi
        if [ -n "$actual" ] && [ "$actual" != "$expected" ]; then
            echo "Checksum mismatch!" >&2
            rm -f "$DEST"
            exit 1
        fi
        echo "Checksum OK"
    fi
fi
rm -f "$checksum_file"

echo "Installed -> $DEST"

# ── PATH setup ───────────────────────────────────────────────────
if echo "$PATH" | grep -q "$BIN_DIR"; then
    echo ""
    echo "Done. Run 'clm' to start."
else
    echo ""
    echo "Adding ${BIN_DIR} to PATH..."

    export_line="export PATH=\"${BIN_DIR}:\$PATH\""
    fish_line="set -gx PATH ${BIN_DIR} \$PATH"

    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rc" ] && ! grep -q "$BIN_DIR" "$rc" 2>/dev/null; then
            printf '\n%s\n' "$export_line" >> "$rc"
            echo "  Added to $(basename $rc)"
        fi
    done

    fish_rc="${HOME}/.config/fish/config.fish"
    if command -v fish >/dev/null 2>&1 || [ -f "$fish_rc" ]; then
        if ! grep -q "$BIN_DIR" "$fish_rc" 2>/dev/null; then
            mkdir -p "$(dirname "$fish_rc")"
            printf '\n%s\n' "$fish_line" >> "$fish_rc"
            echo "  Added to config.fish"
        fi
    fi

    echo ""
    echo "Restart terminal or run: source ~/.bashrc"
    echo "Then: clm"
fi
