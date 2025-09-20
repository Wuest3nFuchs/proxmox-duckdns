#!/usr/bin/env bash

# Quick automatic installer for DuckDNS on Proxmox
# Downloads and runs the full automatic installation script

echo "🦆 DuckDNS Automatic Installer for Proxmox"
echo "========================================="
echo ""

# Verify we're on Proxmox
if ! command -v pct &> /dev/null; then
    echo "❌ This script must be run on a Proxmox VE host"
    echo "   Run this command from the Proxmox host, not from a container"
    exit 1
fi

# Verify we have wget or curl
if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    echo "📦 Installing wget..."
    apt update && apt install -y wget
fi

# URL of the main script
SCRIPT_URL="https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/proxmox-auto-install.sh"

echo "⬇️  Downloading automatic installer..."

# Download the script
if command -v wget &> /dev/null; then
    wget -O /tmp/proxmox-auto-install.sh "$SCRIPT_URL"
else
    curl -o /tmp/proxmox-auto-install.sh "$SCRIPT_URL"
fi

# Verify download
if [[ ! -f /tmp/proxmox-auto-install.sh ]]; then
    echo "❌ Error downloading the script"
    exit 1
fi

# Set permissions
chmod +x /tmp/proxmox-auto-install.sh

echo "✅ Download complete!"
echo ""
echo "🛠️  **CONTINUE WITH INSTALLATION:**"
echo ""
echo "   bash /tmp/proxmox-auto-install.sh"
echo ""
echo "💡 Copy and paste the command above to continue"
echo ""

# Keep the file for manual execution
# The file remains at /tmp/proxmox-auto-install.sh for later use
