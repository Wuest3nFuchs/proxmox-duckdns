#!/usr/bin/env bash

# Instalador rápido automático para DuckDNS en Proxmox
# Descarga y ejecuta el script completo de instalación automática

echo "🦆 Instalador Automático DuckDNS para Proxmox"
echo "============================================="
echo ""

# Verificar que estamos en Proxmox
if ! command -v pct &> /dev/null; then
    echo "❌ Este script debe ejecutarse en un servidor Proxmox VE"
    echo "   Usa este comando desde el host Proxmox, no desde un contenedor"
    exit 1
fi

# Verificar que tenemos wget o curl
if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    echo "📦 Instalando wget..."
    apt update && apt install -y wget
fi

# URL del script principal
SCRIPT_URL="https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/proxmox-auto-install.sh"

echo "⬇️  Descargando instalador automático..."

# Descargar el script
if command -v wget &> /dev/null; then
    wget -O /tmp/proxmox-auto-install.sh "$SCRIPT_URL"
else
    curl -o /tmp/proxmox-auto-install.sh "$SCRIPT_URL"
fi

# Verificar descarga
if [[ ! -f /tmp/proxmox-auto-install.sh ]]; then
    echo "❌ Error al descargar el script"
    exit 1
fi

# Dar permisos
chmod +x /tmp/proxmox-auto-install.sh

echo "✅ ¡Descarga completada!"
echo ""
echo "🛠️  **CONTINÚA CON LA INSTALACIÓN:**"
echo ""
echo "   bash /tmp/proxmox-auto-install.sh"
echo ""
echo "💡 Copia y pega el comando de arriba para continuar"
echo ""

# Mantener el archivo para ejecución manual
# El archivo queda en /tmp/proxmox-auto-install.sh para uso posterior 