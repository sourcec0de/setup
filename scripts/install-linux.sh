#!/usr/bin/env bash
set -euo pipefail

# Linux installer script

# Load shared versions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/versions.sh"

# Directories
SDK_DIR="$HOME/sdk"
LOCAL_BIN="$HOME/.local/bin"
BASHRC="$HOME/.bashrc"

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
    NODE_ARCH="linux-arm64"
    GO_ARCH="linux-arm64"
    GCLOUD_ARCH="linux-arm"
    GH_ARCH="linux_arm64"
else
    NODE_ARCH="linux-x64"
    GO_ARCH="linux-amd64"
    GCLOUD_ARCH="linux-x86_64"
    GH_ARCH="linux_amd64"
fi

echo "==> Detected architecture: $ARCH"

# Check for required dependencies
check_dependencies() {
    local need_install=false
    for cmd in curl python3; do
        if ! command -v "$cmd" &>/dev/null; then
            need_install=true
            break
        fi
    done

    if [[ "$need_install" == "true" ]]; then
        echo "==> Installing required dependencies..."
        if command -v apt-get &>/dev/null; then
            apt-get update -qq
            apt-get install -y -qq curl xz-utils ca-certificates python3
        else
            echo "Error: curl and python3 are required. Please install them manually."
            exit 1
        fi
    fi
}

check_dependencies

# Create directories
echo "==> Creating directories..."
mkdir -p "$SDK_DIR"
mkdir -p "$LOCAL_BIN"

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
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${NODE_ARCH}.tar.xz"

    echo "==> Extracting Node.js..."
    tar -xJf "$SDK_DIR/node.tar.gz" -C "$SDK_DIR/"
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
    echo "==> Configuring $BASHRC..."

    local marker="# === setup/go.sh managed ==="

    # Remove existing managed block if present
    if grep -q "$marker" "$BASHRC" 2>/dev/null; then
        sed -i "/$marker/,/$marker/d" "$BASHRC"
    fi

    # Append managed block
    cat >> "$BASHRC" << EOF

$marker
export PATH="\$HOME/.local/bin:\$PATH"
export PATH="\$HOME/sdk/node${NODE_VERSION}/bin:\$PATH"
export GOROOT="\$HOME/sdk/go${GO_VERSION}"
export PATH="\$HOME/sdk/go${GO_VERSION}/bin:\$HOME/go/bin:\$PATH"

# Google Cloud SDK
if [ -f "\$HOME/sdk/google-cloud-sdk/path.bash.inc" ]; then
    source "\$HOME/sdk/google-cloud-sdk/path.bash.inc"
fi
if [ -f "\$HOME/sdk/google-cloud-sdk/completion.bash.inc" ]; then
    source "\$HOME/sdk/google-cloud-sdk/completion.bash.inc"
fi
$marker
EOF

    echo "==> bashrc configured"
}

install_gh() {
    if command -v gh &>/dev/null; then
        echo "==> gh CLI already installed, skipping..."
        return
    fi

    echo "==> Installing gh CLI..."

    # Get latest gh release version
    local gh_version
    gh_version=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

    curl -fsSL -o "$SDK_DIR/gh.tar.gz" \
        "https://github.com/cli/cli/releases/download/v${gh_version}/gh_${gh_version}_${GH_ARCH}.tar.gz"

    tar -xzf "$SDK_DIR/gh.tar.gz" -C "$SDK_DIR/"
    cp "$SDK_DIR/gh_${gh_version}_${GH_ARCH}/bin/gh" "$LOCAL_BIN/"
    rm -rf "$SDK_DIR/gh.tar.gz" "$SDK_DIR/gh_${gh_version}_${GH_ARCH}"

    echo "==> gh CLI installed: $("$LOCAL_BIN/gh" --version | head -1)"
}

install_fastfetch() {
    if command -v fastfetch &>/dev/null; then
        echo "==> fastfetch already installed, skipping..."
        return
    fi

    echo "==> Installing fastfetch..."

    # Get latest fastfetch release
    local ff_version
    ff_version=$(curl -fsSL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

    local ff_arch
    if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        ff_arch="aarch64"
    else
        ff_arch="amd64"
    fi

    curl -fsSL -o "$SDK_DIR/fastfetch.tar.gz" \
        "https://github.com/fastfetch-cli/fastfetch/releases/download/${ff_version}/fastfetch-linux-${ff_arch}.tar.gz"

    tar -xzf "$SDK_DIR/fastfetch.tar.gz" -C "$SDK_DIR/"
    cp "$SDK_DIR/fastfetch-linux-${ff_arch}/usr/bin/fastfetch" "$LOCAL_BIN/"
    rm -rf "$SDK_DIR/fastfetch.tar.gz" "$SDK_DIR/fastfetch-linux-${ff_arch}"

    echo "==> fastfetch installed: $("$LOCAL_BIN/fastfetch" --version | head -1)"
}

install_tree_sitter() {
    if command -v tree-sitter &>/dev/null; then
        echo "==> tree-sitter already installed, skipping..."
        return
    fi

    echo "==> Installing tree-sitter..."

    # Get latest tree-sitter-cli release
    local ts_version
    ts_version=$(curl -fsSL https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

    local ts_arch
    if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        ts_arch="linux-arm64"
    else
        ts_arch="linux-x64"
    fi

    curl -fsSL -o "$LOCAL_BIN/tree-sitter.gz" \
        "https://github.com/tree-sitter/tree-sitter/releases/download/v${ts_version}/tree-sitter-${ts_arch}.gz"

    gunzip -f "$LOCAL_BIN/tree-sitter.gz"
    chmod +x "$LOCAL_BIN/tree-sitter"

    echo "==> tree-sitter installed: $("$LOCAL_BIN/tree-sitter" --version)"
}

main() {
    echo "==> Starting Linux environment setup..."

    install_gcloud
    install_node
    install_go
    configure_shell
    install_gh
    install_fastfetch
    install_tree_sitter

    echo ""
    echo "==> Setup complete!"
    echo "    Run 'source $BASHRC' or open a new terminal to apply changes."
    echo ""
    echo "    Post-install steps:"
    echo "    1. gcloud auth login"
    echo "    2. gcloud auth application-default login"
    echo "    3. gcloud config configurations create <name>"
    echo "    4. gcloud config set project <project-id>"
    echo "    5. gh auth login"
}

main "$@"
