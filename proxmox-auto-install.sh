#!/usr/bin/env bash

# Automatic DuckDNS installer for Proxmox
# Runs from the Proxmox host and creates everything automatically
# Awesome! — Fully automated for the Boricua community

# Basic configuration without strict error handling

echo "🦆 ===== DUCKDNS AUTOMATIC INSTALLER FOR PROXMOX ====="
echo "This script will create an LXC container and configure DuckDNS automatically"
echo ""

# Function to show messages
show_info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}

show_success() {
    echo -e "\e[32m[OK]\e[0m $1"
}

show_error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

# Verify we're on Proxmox
if ! command -v pct &> /dev/null; then
    show_error "This script must be run on a Proxmox VE server"
    exit 1
fi

# Ask user for information
echo "📝 Initial configuration:"

echo -n "DuckDNS token: "
read DUCKDNS_TOKEN

echo -n "Subdomain (e.g. mydomain): "
read DUCKDNS_DOMAIN

echo -n "Container ID (e.g. 100): "
read CONTAINER_ID

echo -n "Container hostname [duckdns]: "
read CONTAINER_HOSTNAME
CONTAINER_HOSTNAME=${CONTAINER_HOSTNAME:-duckdns}

echo -n "Container root password [duckdns]: "
read CONTAINER_PASSWORD
CONTAINER_PASSWORD=${CONTAINER_PASSWORD:-duckdns}

echo -n "Storage [local-lvm]: "
read STORAGE
STORAGE=${STORAGE:-local-lvm}

echo -n "Network bridge [vmbr0]: "
read NETWORK_BRIDGE
NETWORK_BRIDGE=${NETWORK_BRIDGE:-vmbr0}

# Validate critical inputs
if [ -z "$DUCKDNS_TOKEN" ]; then
    show_error "DuckDNS token is required"
    exit 1
fi

if [ -z "$DUCKDNS_DOMAIN" ]; then
    show_error "DuckDNS subdomain is required"
    exit 1
fi

if [ -z "$CONTAINER_ID" ]; then
    show_error "Container ID is required"
    exit 1
fi

# Default configuration
CONTAINER_MEMORY=${CONTAINER_MEMORY:-512}
CONTAINER_DISK=${CONTAINER_DISK:-2}
CONTAINER_CORES=${CONTAINER_CORES:-1}
TEMPLATE_NAME="ubuntu-22.04-standard"

show_info "Searching for available templates..."
# Show available templates for reference
echo "📋 Templates available on the system:"
pct template list | head -10

# Find templates in order of preference
TEMPLATE=""

# Try Ubuntu 22.04 first
TEMPLATE=$(pct template list | grep -i ubuntu | grep -E "(22\.04|22-04)" | head -1 | awk '{print $2}')
if [ -n "$TEMPLATE" ]; then
    show_success "✅ Using Ubuntu 22.04 template: $TEMPLATE"
else
    # If no Ubuntu, look for Debian 12
    TEMPLATE=$(pct template list | grep -i debian | grep -E "(12|12\.)" | head -1 | awk '{print $2}')
    if [ -n "$TEMPLATE" ]; then
        show_success "✅ Using Debian 12 template: $TEMPLATE"
        show_info "💡 Note: Debian 12 is used because Ubuntu 22.04 is not available"
    else
        # Find any recent Ubuntu or Debian template
        TEMPLATE=$(pct template list | grep -iE "(ubuntu|debian)" | head -1 | awk '{print $2}')
        if [ -n "$TEMPLATE" ]; then
            show_success "✅ Using available template: $TEMPLATE"
            show_info "💡 Note: Using the most recent template available"
        else
            # If none found, download Ubuntu 22.04
            show_info "⬇️ No templates found. Downloading Ubuntu 22.04..."
            pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
            TEMPLATE="ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
            show_success "✅ Template downloaded: $TEMPLATE"
        fi
    fi
fi

show_success "Template found: $TEMPLATE"

# Verify the container ID does not already exist
if pct status $CONTAINER_ID &> /dev/null; then
    show_error "Container ID $CONTAINER_ID already exists"
    exit 1
fi

show_info "Creating LXC container..."
# Create the LXC container with autoboot enabled
pct create $CONTAINER_ID local:vztmpl/$TEMPLATE \
    --hostname $CONTAINER_HOSTNAME \
    --memory $CONTAINER_MEMORY \
    --cores $CONTAINER_CORES \
    --rootfs $STORAGE:$CONTAINER_DISK \
    --net0 name=eth0,bridge=$NETWORK_BRIDGE,ip=dhcp \
    --password $CONTAINER_PASSWORD \
    --start 1 \
    --onboot 1 \
    --unprivileged 1 \
    --features nesting=1

show_success "Container $CONTAINER_ID created successfully"

# Wait for the container to be ready
show_info "Waiting for the container to be ready..."
sleep 30

# Function to run commands inside the container
run_in_container() {
    pct exec $CONTAINER_ID -- bash -c "$1"
}

show_info "Updating system inside the container..."
# Update the system
run_in_container "apt update && apt upgrade -y"

show_info "Installing dependencies..."
# Install dependencies
run_in_container "apt install -y curl cron wget"

show_info "Configuring DuckDNS..."
# Create directory for DuckDNS
run_in_container "mkdir -p /opt/duckdns"

# Create an improved DuckDNS update script
run_in_container "cat > /opt/duckdns/duck.sh << 'EOF'
#!/bin/bash
# DuckDNS update script — runs every 5 minutes
# Keeps the IP updated automatically — awesome!

# Get current IP
CURRENT_IP=\$(curl -s ifconfig.me 2>/dev/null)
TIMESTAMP=\$(date '+%Y-%m-%d %H:%M:%S')

# Create log directory if it doesn't exist
mkdir -p /var/log/duckdns

# Update DuckDNS
RESULT=\$(echo url=\"https://www.duckdns.org/update?domains=$DUCKDNS_DOMAIN&token=$DUCKDNS_TOKEN&ip=\" | curl -k -s -K -)

# Save result to main log
echo \"\$RESULT\" > ~/duckdns.log

# Save detailed log
echo \"[\$TIMESTAMP] IP: \$CURRENT_IP - Result: \$RESULT\" >> /var/log/duckdns/detailed.log

# Keep only the last 100 lines of the detailed log
tail -n 100 /var/log/duckdns/detailed.log > /var/log/duckdns/detailed.log.tmp
mv /var/log/duckdns/detailed.log.tmp /var/log/duckdns/detailed.log
EOF"

# Set permissions on the script
run_in_container "chmod 700 /opt/duckdns/duck.sh"

show_info "Configuring cron for automatic updates..."
# Configure cron to run every 5 minutes
run_in_container "cat > /etc/cron.d/duckdns << 'EOF'
*/5 * * * * root /opt/duckdns/duck.sh >/dev/null 2>&1
EOF"

# Set cron file permissions
run_in_container "chmod 644 /etc/cron.d/duckdns"

# Restart cron
run_in_container "systemctl restart cron"

show_info "Testing first update..."
# Run a first update
run_in_container "/opt/duckdns/duck.sh"

# Check the result
RESULT=$(run_in_container "cat ~/duckdns.log 2>/dev/null || echo 'No log found'")
if [[ "$RESULT" == *"OK"* ]]; then
    show_success "First update successful: $RESULT"
else
    show_error "Possible error in update: $RESULT"
fi

show_info "Cleaning system..."
# Clean the system
run_in_container "apt autoremove -y && apt autoclean"

# Create an advanced info script inside the container
run_in_container "cat > /root/duckdns-info.sh << 'EOF'
#!/bin/bash
echo \"🦆 ===== DUCKDNS INFORMATION =====\"
echo \"Domain: $DUCKDNS_DOMAIN.duckdns.org\"
echo \"Cron service status:\"
systemctl status cron --no-pager -l
echo \"\"
echo \"Last update:\"
cat ~/duckdns.log 2>/dev/null || echo \"No log available\"
echo \"\"
echo \"To view logs in real time: tail -f ~/duckdns.log\"
echo \"To update manually: /opt/duckdns/duck.sh\"
EOF"

run_in_container "chmod +x /root/duckdns-info.sh"

# Create a welcome script that runs at login
run_in_container "cat > /opt/duckdns/welcome.sh << 'EOF'
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e \"${BLUE}\"
echo \"🦆 ===== DUCKDNS LXC CONTAINER =====\"
echo -e \"${NC}\"

# Domain info
echo -e \"${GREEN}🌐 Domain:${NC} $DUCKDNS_DOMAIN.duckdns.org\"

# Get current server IP
CURRENT_IP=\$(curl -s ifconfig.me 2>/dev/null || echo \"Unavailable\")
echo -e \"${GREEN}📡 Current Server IP:${NC} \$CURRENT_IP\"

# Check last update
if [ -f ~/duckdns.log ]; then
    LAST_UPDATE=\$(stat -c %y ~/duckdns.log 2>/dev/null | cut -d. -f1)
    LAST_RESULT=\$(cat ~/duckdns.log 2>/dev/null)
    
    echo -e \"${GREEN}🕐 Last Update:${NC} \$LAST_UPDATE\"
    
    if [[ \"\$LAST_RESULT\" == *\"OK\"* ]]; then
        echo -e \"${GREEN}✅ Status:${NC} Update successful\"
    elif [[ \"\$LAST_RESULT\" == *\"KO\"* ]]; then
        echo -e \"${RED}❌ Status:${NC} Update error\"
    else
        echo -e \"${YELLOW}⚠️  Status:${NC} Unknown result: \$LAST_RESULT\"
    fi
    
    # Show history of last 3 updates
    if [ -f /var/log/duckdns/detailed.log ]; then
        echo -e \"${BLUE}📈 Recent updates:${NC}\"
        tail -n 3 /var/log/duckdns/detailed.log | while read line; do
            if [[ \"\$line\" == *\"OK\"* ]]; then
                echo -e \"  ${GREEN}✓${NC} \$line\"
            elif [[ \"\$line\" == *\"KO\"* ]]; then
                echo -e \"  ${RED}✗${NC} \$line\"
            else
                echo -e \"  ${YELLOW}?${NC} \$line\"
            fi
        done
    fi
else
    echo -e \"${YELLOW}⚠️  Status:${NC} No updates recorded\"
fi

# Check if cron is running
if systemctl is-active --quiet cron; then
    echo -e \"${GREEN}🔄 Cron Service:${NC} Active (updates every 5 minutes)\"
else
    echo -e \"${RED}❌ Cron Service:${NC} Inactive\"
fi

# Check DNS resolution
DNS_IP=\$(nslookup $DUCKDNS_DOMAIN.duckdns.org 2>/dev/null | grep -A1 \"Name:\" | grep \"Address:\" | awk '{print \$2}' | head -1)
if [ -n \"\$DNS_IP\" ]; then
    echo -e \"${GREEN}🔍 DNS Resolves To:${NC} \$DNS_IP\"
    if [ \"\$DNS_IP\" = \"\$CURRENT_IP\" ]; then
        echo -e \"${GREEN}✅ DNS Synced:${NC} IP matches\"
    else
        echo -e \"${YELLOW}⚠️  DNS Out of Date:${NC} IP does not match\"
    fi
else
    echo -e \"${RED}❌ DNS:${NC} Could not resolve domain\"
fi

echo \"\"
echo -e \"${BLUE}📋 Useful commands:${NC}\"
echo \"  • View logs in real time: tail -f ~/duckdns.log\"
echo \"  • View full history: tail -f /var/log/duckdns/detailed.log\"
echo \"  • Update now: /opt/duckdns/duck.sh\"
echo \"  • View full info: /root/duckdns-info.sh\"
echo \"  • Cron status: systemctl status cron\"
echo \"  • Show this info: duckdns\"
echo \"\"
echo -e \"${BLUE}🚀 Developed with ❤️ for the Proxmox community${NC}\"
echo \"\"
EOF"

run_in_container "chmod +x /opt/duckdns/welcome.sh"

# Add the welcome script to .bashrc so it runs at login
run_in_container "echo '' >> /root/.bashrc"
run_in_container "echo '# Show DuckDNS info on login' >> /root/.bashrc"
run_in_container "echo '/opt/duckdns/welcome.sh' >> /root/.bashrc"

# Also create an alias to show info quickly
run_in_container "echo 'alias duckdns=\"/opt/duckdns/welcome.sh\"' >> /root/.bashrc"

show_info "Configuring autologin for the console..."
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

show_info "Restarting container to apply autologin..."
# Restart the container so autologin takes effect
pct stop $CONTAINER_ID
sleep 2
pct start $CONTAINER_ID

show_success "Installation completed successfully!"
echo ""
echo "🎉 ===== INSTALLATION SUMMARY ====="
echo "📦 Container ID: $CONTAINER_ID"
echo "🏷️  Hostname: $CONTAINER_HOSTNAME"
echo "🌐 Domain: $DUCKDNS_DOMAIN.duckdns.org"
echo "🔑 Root password: $CONTAINER_PASSWORD"
echo "💾 Storage: $STORAGE"
echo "🔧 Network: $NETWORK_BRIDGE"
echo "🚀 Autoboot: Enabled"
echo "🔓 Autologin: Enabled (automatic console)"
echo ""
echo "📋 USEFUL COMMANDS:"
echo "• Enter the container: pct enter $CONTAINER_ID"
echo "• View information: pct exec $CONTAINER_ID -- /root/duckdns-info.sh"
echo "• Stop container: pct stop $CONTAINER_ID"
echo "• Start container: pct start $CONTAINER_ID"
echo ""
echo "🔍 VERIFICATION:"
echo "• Verify your domain: nslookup $DUCKDNS_DOMAIN.duckdns.org"
echo "• Current IP: curl -s ifconfig.me"
echo ""
echo "✅ ENABLED FEATURES:"
echo "• ✅ DuckDNS configured and running automatically"
echo "• ✅ IP update every 5 minutes"
echo "• ✅ Autoboot at Proxmox startup"
echo "• ✅ Autologin on console (no password)"
echo "• ✅ Welcome screen with real-time information"
echo ""
echo "💡 IMPORTANT NOTE:"
echo "• Proxmox console: pct enter $CONTAINER_ID (NO PASSWORD - autologin)"
echo "• SSH: ssh root@CONTAINER_IP (password: $CONTAINER_PASSWORD)"
echo "• If autologin doesn't work immediately, use: pct reboot $CONTAINER_ID"
echo ""
echo "🚀 Developed 🇵🇷 Puerto Rico with lots of ☕️ coffee for the Proxmox community!"
