#!/usr/bin/env bash
set -euo pipefail

# macOS installer script

# Load shared versions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/versions.sh"

# Directories
SDK_DIR="$HOME/sdk"
LOCAL_BIN="$HOME/.local/bin"
ZPROFILE="$HOME/.zprofile"

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    NODE_ARCH="darwin-arm64"
    GO_ARCH="darwin-arm64"
    GCLOUD_ARCH="darwin-arm"
else
    NODE_ARCH="darwin-x64"
    GO_ARCH="darwin-amd64"
    GCLOUD_ARCH="darwin-x86_64"
fi

echo "==> Detected architecture: $ARCH"

# Create directories
echo "==> Creating directories..."
mkdir -p "$SDK_DIR"
mkdir -p "$LOCAL_BIN"

install_homebrew() {
    if command -v brew &>/dev/null; then
        echo "==> Homebrew already installed, skipping..."
        return
    fi

    echo "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_gcloud() {
    if [[ -d "$SDK_DIR/google-cloud-sdk" ]]; then
        echo "==> Google Cloud SDK already installed, skipping..."
        return
    fi

    echo "==> Downloading Google Cloud SDK..."
    curl -fsSL -o "$SDK_DIR/google-cloud-cli.tar.gz" \
        "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_ARCH}.tar.gz"

    echo "==> Extracting Google Cloud SDK..."
    tar -xzf "$SDK_DIR/google-cloud-cli.tar.gz" -C "$SDK_DIR/"
    rm "$SDK_DIR/google-cloud-cli.tar.gz"

    echo "==> Installing gcloud components..."
    "$SDK_DIR/google-cloud-sdk/bin/gcloud" components install \
        kubectl alpha beta docker-credential-gcr gke-gcloud-auth-plugin --quiet
}

install_node() {
    local node_dir="$SDK_DIR/node${NODE_VERSION}"

    if [[ -d "$node_dir" ]]; then
        echo "==> Node.js ${NODE_VERSION} already installed, skipping..."
        return
    fi

    echo "==> Downloading Node.js ${NODE_VERSION}..."
    curl -fsSL -o "$SDK_DIR/node.tar.gz" \
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${NODE_ARCH}.tar.gz"

    echo "==> Extracting Node.js..."
    tar -xzf "$SDK_DIR/node.tar.gz" -C "$SDK_DIR/"
    mv "$SDK_DIR/node-v${NODE_VERSION}-${NODE_ARCH}" "$node_dir"
    rm "$SDK_DIR/node.tar.gz"

    echo "==> Node.js installed: $("$node_dir/bin/node" --version)"
}

install_go() {
    local go_dir="$SDK_DIR/go${GO_VERSION}"

    if [[ -d "$go_dir" ]]; then
        echo "==> Go ${GO_VERSION} already installed, skipping..."
        return
    fi

    echo "==> Downloading Go ${GO_VERSION}..."
    curl -fsSL -o "$SDK_DIR/go.tar.gz" \
        "https://go.dev/dl/go${GO_VERSION}.${GO_ARCH}.tar.gz"

    echo "==> Extracting Go..."
    tar -xzf "$SDK_DIR/go.tar.gz" -C "$SDK_DIR/"
    mv "$SDK_DIR/go" "$go_dir"
    rm "$SDK_DIR/go.tar.gz"

    echo "==> Go installed: $("$go_dir/bin/go" version)"
}

configure_shell() {
    echo "==> Configuring $ZPROFILE..."

    local marker="# === setup/go.sh managed ==="

    # Remove existing managed block if present
    if grep -q "$marker" "$ZPROFILE" 2>/dev/null; then
        sed -i '' "/$marker/,/$marker/d" "$ZPROFILE"
    fi

    # Append managed block
    cat >> "$ZPROFILE" << EOF

$marker
export PATH="\$HOME/.local/bin:\$PATH"
export PATH="\$HOME/sdk/node${NODE_VERSION}/bin:\$PATH"
export GOROOT="\$HOME/sdk/go${GO_VERSION}"
export PATH="\$HOME/sdk/go${GO_VERSION}/bin:\$HOME/go/bin:\$PATH"

# Google Cloud SDK
if [ -f "\$HOME/sdk/google-cloud-sdk/path.zsh.inc" ]; then
    source "\$HOME/sdk/google-cloud-sdk/path.zsh.inc"
fi
if [ -f "\$HOME/sdk/google-cloud-sdk/completion.zsh.inc" ]; then
    source "\$HOME/sdk/google-cloud-sdk/completion.zsh.inc"
fi
$marker
EOF

    echo "==> zprofile configured"
}

install_gh() {
    if command -v gh &>/dev/null; then
        echo "==> gh CLI already installed, skipping..."
        return
    fi

    echo "==> Installing gh CLI via Homebrew..."
    brew install gh
}

install_fastfetch() {
    if command -v fastfetch &>/dev/null; then
        echo "==> fastfetch already installed, skipping..."
        return
    fi

    echo "==> Installing fastfetch via Homebrew..."
    brew install fastfetch
}

install_tree_sitter() {
    if command -v tree-sitter &>/dev/null; then
        echo "==> tree-sitter already installed, skipping..."
        return
    fi

    echo "==> Installing tree-sitter-cli via Homebrew..."
    brew install tree-sitter-cli
}

main() {
    echo "==> Starting macOS environment setup..."

    install_homebrew
    install_gcloud
    install_node
    install_go
    configure_shell
    install_gh
    install_fastfetch
    install_tree_sitter

    echo ""
    echo "==> Setup complete!"
    echo "    Run 'source $ZPROFILE' or open a new terminal to apply changes."
    echo ""
    echo "    Post-install steps:"
    echo "    1. gcloud auth login"
    echo "    2. gcloud auth application-default login"
    echo "    3. gcloud config configurations create <name>"
    echo "    4. gcloud config set project <project-id>"
    echo "    5. gh auth login"
}

main "$@"
