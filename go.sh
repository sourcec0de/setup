#!/usr/bin/env bash
set -euo pipefail

# Entry point: detect OS and delegate to platform-specific installer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS=$(uname -s)

case "$OS" in
    Darwin)
        echo "==> Detected macOS"
        exec "$SCRIPT_DIR/scripts/install-darwin.sh"
        ;;
    Linux)
        echo "==> Detected Linux"
        exec "$SCRIPT_DIR/scripts/install-linux.sh"
        ;;
    *)
        echo "Error: Unsupported operating system: $OS"
        exit 1
        ;;
esac
