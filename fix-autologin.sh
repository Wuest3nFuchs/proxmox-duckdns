#!/bin/bash

# Script to fix autologin in existing DuckDNS containers
# Usage: ./fix-autologin.sh [CONTAINER_ID]

# Colors for better display
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show colored messages
show_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

show_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to run commands inside the container
run_in_container() {
    pct exec $CONTAINER_ID -- bash -c "$1"
}

echo "🔧 ===== FIX AUTOLOGIN IN DUCKDNS CONTAINER ====="
echo ""

# Check if container ID was provided
if [ -z "$1" ]; then
    echo -n "Container ID to fix: "
    read CONTAINER_ID
else
    CONTAINER_ID=$1
fi

# Verify the container exists
if ! pct status $CONTAINER_ID >/dev/null 2>&1; then
    show_error "Container $CONTAINER_ID does not exist"
    exit 1
fi

# Verify the container is running
if [ "$(pct status $CONTAINER_ID | awk '{print $2}')" != "running" ]; then
    show_info "Starting container $CONTAINER_ID..."
    pct start $CONTAINER_ID
    sleep 3
fi

show_info "Configuring autologin in container $CONTAINER_ID..."

# Configure autologin for the container console
run_in_container "mkdir -p /etc/systemd/system/console-getty.service.d"
run_in_container "cat > /etc/systemd/system/console-getty.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF"

# Also configure autologin for tty1 (main console)
run_in_container "mkdir -p /etc/systemd/system/getty@tty1.service.d"
run_in_container "cat > /etc/systemd/system/getty@tty1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF"

# Configure autologin for container-getty (LXC-specific)
run_in_container "mkdir -p /etc/systemd/system/container-getty@1.service.d"
run_in_container "cat > /etc/systemd/system/container-getty@1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud pts/%I 115200,38400,9600 vt220
EOF"

# Enable autologin services
run_in_container "systemctl daemon-reload"
run_in_container "systemctl enable console-getty.service"
run_in_container "systemctl enable container-getty@1.service"

show_info "Rebooting container to apply changes..."
pct stop $CONTAINER_ID
sleep 2
pct start $CONTAINER_ID

show_success "Autologin configured successfully!"
echo ""
echo "🎉 ===== SUMMARY ====="
echo "📦 Container: $CONTAINER_ID"
echo "🔓 Autologin: Enabled"
echo ""
echo "📋 COMMANDS TO TEST:"
echo "• Enter without password: pct enter $CONTAINER_ID"
echo "• If it doesn't work: pct reboot $CONTAINER_ID"
echo ""
echo "💡 NOTE: Autologin works from the Proxmox console only,"
echo "not via SSH. For SSH you need the container's password."
