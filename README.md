# Setup

Bootstrap a new macOS machine with development tools.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/sourcec0de/setup/main/go.sh | bash
```

## What's Installed

- **Google Cloud SDK** - gcloud, kubectl, alpha, beta, docker-credential-gcr, gke-gcloud-auth-plugin
- **Node.js** - LTS version
- **Go** - Latest stable
- **gh** - GitHub CLI

## Post-Install

After running the installer, open a new terminal and complete these steps:

```bash
# Authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login

# Create and configure a gcloud profile
gcloud config configurations create <name>
gcloud config set project <project-id>

# Authenticate with GitHub
gh auth login
```

## Directory Structure

```
$HOME/
├── sdk/
│   ├── google-cloud-sdk/
│   ├── node24.13.0/
│   └── go1.25.6/
└── .local/bin/
```
