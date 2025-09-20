# 🦆ENGLISH VERSION 
# 🦆DuckDNS for Proxmox LXC

An automated script to set up DuckDNS in Proxmox LXC containers — perfect for keeping your dynamic IP updated without hassle.

## 📋 Requirements

- **Proxmox VE** (any recent version)  
- **LXC template** (Ubuntu 22.04 or Debian 12 — detected automatically)  
- **DuckDNS token** (from https://www.duckdns.org)  
- **Registered subdomain** on DuckDNS

## 🚀 Quick Installation

### Method 1: Full Automatic Install (RECOMMENDED!) 🎯

**Option A: Super Fast (Two steps)** ⚡

```bash
# Step 1: Download the installer
curl -sSL https://raw.githubusercontent.com/Wuest3nFuchs/proxmox-duckdns/main/auto-install.sh | bash

# Step 2: Run the installer (copy and paste the command that appears)
bash /tmp/proxmox-auto-install.sh
```

> **💡 Note:** The first command downloads the installer, the second runs it. This avoids pipe-related issues.

**Option B: Download and Run** 📥

```bash
# From the Proxmox host (SSH or console)
wget https://raw.githubusercontent.com/Wuest3nFuchs/proxmox-duckdns/main/proxmox-auto-install.sh
chmod +x proxmox-auto-install.sh
./proxmox-auto-install.sh
```

What this script does:
- ✅ Automatically creates the LXC container
- ✅ Detects and uses the best available template (Ubuntu 22.04 or Debian 12)
- ✅ Configures network and storage
- ✅ Installs and configures DuckDNS
- ✅ Sets up cron for automatic updates
- ✅ Enables autoboot (container starts with Proxmox)
- ✅ Configures console autologin (no password)
- ✅ Default password: `duckdns` (customizable)
- ✅ Creates a welcome screen with real-time info
- ✅ Tests the first update
- ✅ Ready in ~5 minutes!

### Method 2: Manual Install in Existing Container

#### 1. Create the LXC Container

In Proxmox, create a new LXC container:
- **Template:** Ubuntu 22.04 or Debian 11/12  
- **RAM:** 512MB (sufficient)  
- **Disk:** 2GB (minimum)  
- **Network:** configured with internet access

#### 2. Enter the Container

```bash
# From Proxmox, enter the container
pct enter [CONTAINER_ID]
```

#### 3. Install (Quick Method) 🚀

```bash
# One-line install
curl -sSL https://raw.githubusercontent.com/Wuest3nFuchs/proxmox-duckdns/main/install.sh | sudo bash
```

#### 3. Install (Manual Method)

```bash
# Download the script
wget https://raw.githubusercontent.com/Wuest3nFuchs/proxmox-duckdns/main/duckdns.sh

# Make executable
chmod +x duckdns.sh

# Run as root
sudo ./duckdns.sh
```

### 4. Configure During Install

The script will ask for:
- **DuckDNS token:** your personal token from DuckDNS
- **Subdomain:** just the name (e.g., `mydomain`, not `mydomain.duckdns.org`)

## 🔧 What the Script Does

The installer automatically:

1. Installs required dependencies (`curl` and `cron`)  
2. Creates `/opt/duckdns/` directory  
3. Generates a customized update script  
4. Sets up cron to run every 5 minutes  
5. Starts cron service automatically  
6. Cleans unnecessary packages

## 📁 Files Created

After installation you'll find:

/opt/duckdns/duck.sh          # Update script  
/opt/duckdns/welcome.sh       # Welcome screen  
/etc/cron.d/duckdns           # Cron configuration  
~/duckdns.log                 # Update log  
/var/log/duckdns/detailed.log # Detailed history

## 🔓 Accessing the Container

### Proxmox Console (Recommended)
```bash
# Direct access without password (autologin enabled)
pct enter [CONTAINER_ID]
```

### SSH (Optional)
```bash
# SSH access (requires password)
ssh root@CONTAINER_IP
# Default password: duckdns
```

### Autoboot
The container starts automatically when Proxmox boots.

## 🖥️ Welcome Screen

When you enter the container (`pct enter [ID]`) you'll see:

- 🌐 Configured domain  
- 📡 Current server IP  
- 🕐 Last update and result  
- 📈 History of last 3 updates  
- 🔄 Cron service status  
- 🔍 Real-time DNS verification  
- 📋 Useful commands available

Quick command: run `duckdns` anytime to view info.

## 🔍 Verify It Works

Check cron:
```bash
# See if cron is active
systemctl status cron

# Verify cron config
cat /etc/cron.d/duckdns
```

Run manually:
```bash
# Test the update script
/opt/duckdns/duck.sh

# View result
cat ~/duckdns.log

# View detailed history
tail -f /var/log/duckdns/detailed.log

# Show full info
duckdns
```

Verify DNS:
```bash
# Check that your domain resolves
nslookup yourdomain.duckdns.org
```

## 🛠️ Troubleshooting

### Auto installer errors

Error: "This script must be run on a Proxmox VE host"
```bash
# Ensure you're on the PROXMOX HOST, not inside a container
# SSH into your Proxmox server directly
ssh root@YOUR_PROXMOX_IP
```

Auto-installer not working:
```bash
# Fix 1: Use the two-step method
curl -sSL https://raw.githubusercontent.com/Wuest3nFuchs/proxmox-duckdns/main/auto-install.sh | bash
bash /tmp/proxmox-auto-install.sh

# Fix 2: Download and run step-by-step
wget https://raw.githubusercontent.com/Wuest3nFuchs/proxmox-duckdns/main/proxmox-auto-install.sh
chmod +x proxmox-auto-install.sh
./proxmox-auto-install.sh
```

Autologin not working:
```bash
# Fix autologin in an existing container
wget https://raw.githubusercontent.com/Wuest3nFuchs/proxmox-duckdns/main/fix-autologin.sh
chmod +x fix-autologin.sh
./fix-autologin.sh [CONTAINER_ID]

# Or manually:
pct reboot [CONTAINER_ID]
```

Container not created:
```bash
# Check ID not in use
pct list

# Check storage exists
pvesm status

# Check available templates
pct template list
```

Permission or network errors:
```bash
# Check network config
ip addr show

# Check network bridge
brctl show
```

General issues

Cron not running:
```bash
# Restart cron
systemctl restart cron

# Check cron logs
journalctl -u cron
```

Script not updating IP:
```bash
# Check connectivity
curl -I https://www.duckdns.org

# Check token and domain in script
cat /opt/duckdns/duck.sh
```

Change update frequency:
```bash
# Edit cron file (default every 5 minutes)
nano /etc/cron.d/duckdns

# Examples:
# */1 * * * *     # Every minute
# */10 * * * *    # Every 10 minutes
# 0 */1 * * *     # Every hour
```

## 🔄 Uninstall

If you need to remove DuckDNS:
```bash
# Remove cron
rm /etc/cron.d/duckdns
systemctl restart cron

# Remove files
rm -rf /opt/duckdns/
rm ~/duckdns.log
```

## 📝 Important Notes

- **Compatibility:** Works with Ubuntu 22.04 and Debian 12 (auto-detected)  
- **Templates:** The script automatically picks the best template available  
- **Autologin:** Proxmox console requires no password (auto-configured)  
- **SSH password:** Default is `duckdns` (changeable during install)  
- **Autoboot:** Container starts with Proxmox boot  
- **Security:** Script runs as root — only run if you trust the code  
- **Logs:** Logs stored in `~/duckdns.log` for debugging  
- **Firewall:** No extra ports required  
- **Backup:** Consider backing up config before major changes

## 🤝 Contribute

Found a bug or have an improvement?
1. Fork the repo  
2. Create a feature branch (`git checkout -b feature/amazing-improvement`)  
3. Commit your changes (`git commit -am 'Add amazing improvement'`)  
4. Push the branch (`git push origin feature/amazing-improvement`)  
5. Open a Pull Request

## 📜 License

This project is under the MIT License — see the LICENSE file for details.

## ⭐ Was this helpful?

If this script helped you, give the repo a star! ⭐

---

Developed in Puerto Rico with lots of coffee for the Proxmox community ❤️
