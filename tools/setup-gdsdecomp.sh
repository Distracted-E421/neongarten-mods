#!/usr/bin/env bash
# Setup gdsdecomp for Neongarten modding
# Downloads the latest release from GitHub

set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
GDSDECOMP_DIR="$TOOLS_DIR/gdsdecomp"
GITHUB_REPO="GDRETools/gdsdecomp"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          gdsdecomp Setup for Neongarten Modding              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check for required tools
if ! command -v curl &> /dev/null; then
    echo "❌ curl is required but not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    exit 1
fi

# Create directory
mkdir -p "$GDSDECOMP_DIR"
cd "$GDSDECOMP_DIR"

# Get latest release info
echo "📥 Fetching latest release info from GitHub..."
RELEASE_INFO=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest")
TAG_NAME=$(echo "$RELEASE_INFO" | jq -r '.tag_name')
echo "   Latest version: $TAG_NAME"

# Find Linux asset
LINUX_ASSET=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | contains("linux")) | .browser_download_url' | head -1)

if [ -z "$LINUX_ASSET" ] || [ "$LINUX_ASSET" = "null" ]; then
    echo "❌ Could not find Linux release asset"
    echo ""
    echo "Available assets:"
    echo "$RELEASE_INFO" | jq -r '.assets[].name'
    echo ""
    echo "Please download manually from:"
    echo "https://github.com/$GITHUB_REPO/releases/latest"
    exit 1
fi

FILENAME=$(basename "$LINUX_ASSET")
echo "📦 Downloading $FILENAME..."
curl -L -o "$FILENAME" "$LINUX_ASSET"

# Extract
echo "📂 Extracting..."
if [[ "$FILENAME" == *.zip ]]; then
    unzip -o "$FILENAME"
    rm "$FILENAME"
elif [[ "$FILENAME" == *.tar.gz ]]; then
    tar -xzf "$FILENAME"
    rm "$FILENAME"
fi

# Find and make executable
GDRE_BIN=$(find . -name "gdre_tools*" -o -name "GDRE_Tools*" | grep -v ".zip" | head -1)
if [ -n "$GDRE_BIN" ]; then
    chmod +x "$GDRE_BIN"
    echo ""
    echo "✅ gdsdecomp installed successfully!"
    echo ""
    echo "📍 Location: $GDSDECOMP_DIR/$GDRE_BIN"
    echo ""
    echo "🚀 Usage:"
    echo "   # List PCK contents"
    echo "   $GDRE_BIN --headless --list-files=<pck>"
    echo ""
    echo "   # Full project recovery (decompile everything)"
    echo "   $GDRE_BIN --headless --recover=<pck> --output=./recovered"
    echo ""
    echo "   # Convert binary resources to text"
    echo "   $GDRE_BIN --headless --bin-to-txt=<file.res>"
    echo ""
    
    # Create convenience symlink
    ln -sf "$GDRE_BIN" "$TOOLS_DIR/gdre"
    echo "🔗 Created symlink: $TOOLS_DIR/gdre"
else
    echo "⚠️  Could not find gdre_tools binary after extraction"
    echo "   Contents of $GDSDECOMP_DIR:"
    ls -la "$GDSDECOMP_DIR"
fi

