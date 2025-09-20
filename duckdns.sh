#!/usr/bin/env bash

# DuckDNS Installer Standalone
# Script to install and configure DuckDNS in Proxmox LXC containers
# Keeps your dynamic IP updated automatically — awesome!

echo "===== DuckDNS Installer ====="

# Ask user for required data
read -r -p "Enter your DuckDNS token: " DUCKDNS_TOKEN
read -r -p "Enter your subdomain (e.g. mydomain): " DUCKDNS_DOMAIN

echo "[INFO] Installing curl and cron..."
# Update packages first
apt update
# Install curl for HTTP requests and cron for scheduling
apt install -y curl cron
echo "[OK] curl and cron installed."

echo "[INFO] Configuring DuckDNS..."
# Create directory for the script
mkdir -p /opt/duckdns
# Generate the update script that runs automatically
cat <<EOF >/opt/duckdns/duck.sh
#!/bin/bash
# This script runs every 5 minutes to keep the IP updated
echo url="https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=" | curl -k -o ~/duckdns.log -K -
EOF

# Set execution permissions for the owner only
chmod 700 /opt/duckdns/duck.sh

# Configure cron to run the script every 5 minutes
cat <<EOF >/etc/cron.d/duckdns
*/5 * * * * root /opt/duckdns/duck.sh >/dev/null 2>&1
EOF

# Correct permissions for the cron file
chmod 644 /etc/cron.d/duckdns
# Restart cron to apply the new configuration
systemctl restart cron

echo "[OK] DuckDNS configured and active."

echo "[INFO] Cleaning up..."
# Remove packages that are no longer needed
apt autoremove -y
# Clean apt cache to free space
apt autoclean -y
echo "[OK] Cleanup complete."

echo "===== DuckDNS Installed Successfully ====="
