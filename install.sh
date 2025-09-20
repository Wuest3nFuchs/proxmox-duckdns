#!/usr/bin/env bash

# Quick DuckDNS installer for Proxmox LXC
# This script downloads and runs the main installer

echo "🦆 Quick DuckDNS Installer for Proxmox LXC"
echo "========================================="

# Check running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (sudo)"
   exit 1
fi

# Ensure wget or curl is available
if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    echo "📦 Installing wget..."
    apt update && apt install -y wget
fi

# URL of the main script
SCRIPT_URL="https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/duckdns.sh"

echo "⬇️  Downloading installer..."

# Download the main script
if command -v wget &> /dev/null; then
    wget -O /tmp/duckdns.sh "$SCRIPT_URL"
else
    curl -o /tmp/duckdns.sh "$SCRIPT_URL"
fi

# Verify download
if [[ ! -f /tmp/duckdns.sh ]]; then
    echo "❌ Error downloading the script"
    exit 1
fi

# Make executable
chmod +x /tmp/duckdns.sh

echo "🚀 Running installer..."
echo ""

# Execute the main script
/tmp/duckdns.sh

# Clean up temporary file
rm -f /tmp/duckdns.sh

echo ""
echo "✅ Installation complete!"
echo "Your DuckDNS is now configured and running 🎉"
