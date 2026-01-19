#!/usr/bin/env bash
set -euo pipefail

# Verification script for macOS (darwin)

# Load shared versions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/versions.sh"

# Set up PATH (include Homebrew for Apple Silicon and Intel)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/sdk/node${NODE_VERSION}/bin:$PATH"
export PATH="$HOME/sdk/go${GO_VERSION}/bin:$HOME/go/bin:$PATH"
export PATH="$HOME/sdk/google-cloud-sdk/bin:$PATH"
export GOROOT="$HOME/sdk/go${GO_VERSION}"

echo "==> DEBUG: PATH=$PATH"
echo "==> DEBUG: Checking brew location..."
command -v brew || echo "brew not in PATH"
ls -la /opt/homebrew/bin/brew 2>/dev/null || echo "/opt/homebrew/bin/brew not found"
ls -la /usr/local/bin/brew 2>/dev/null || echo "/usr/local/bin/brew not found"

echo "==> Verifying directory structure..."
test -d "$HOME/sdk/google-cloud-sdk" || { echo "FAIL: google-cloud-sdk not found"; exit 1; }
test -d "$HOME/sdk/node${NODE_VERSION}" || { echo "FAIL: node${NODE_VERSION} not found"; exit 1; }
test -d "$HOME/sdk/go${GO_VERSION}" || { echo "FAIL: go${GO_VERSION} not found"; exit 1; }
test -d "$HOME/.local/bin" || { echo "FAIL: .local/bin not found"; exit 1; }
echo "All directories exist"

echo "==> Checking brew..."
brew --version || { echo "FAIL: brew not working"; exit 1; }

echo "==> Checking node..."
node --version
node --version | grep -q "v${NODE_VERSION}" || { echo "FAIL: Expected node v${NODE_VERSION}"; exit 1; }

echo "==> Checking npm..."
npm --version

echo "==> Checking go..."
go version
go version | grep -q "go${GO_VERSION}" || { echo "FAIL: Expected go${GO_VERSION}"; exit 1; }

echo "==> Checking gcloud..."
gcloud --version

echo "==> Checking kubectl..."
kubectl version --client

echo "==> Checking gh..."
gh --version

echo "==> Checking fastfetch..."
fastfetch --version

echo "==> Checking tree-sitter..."
tree-sitter --version

echo "==> Checking bpytop..."
bpytop --version

echo "==> Verifying GOROOT..."
expected="$HOME/sdk/go${GO_VERSION}"
if [[ "$GOROOT" != "$expected" ]]; then
    echo "FAIL: GOROOT is '$GOROOT', expected '$expected'"
    exit 1
fi
echo "GOROOT is correctly set to $GOROOT"

echo ""
echo "==> All macOS verifications passed!"
