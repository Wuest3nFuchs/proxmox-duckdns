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

echo "🚀 Ejecutando instalador automático..."
echo ""

# Ejecutar el script con bash y redirigir entrada desde /dev/tty
if bash /tmp/proxmox-auto-install.sh < /dev/tty; then
    echo ""
    echo "✅ ¡Proceso completado exitosamente!"
else
    echo ""
    echo "⚠️  El script automático falló. Ejecutando manualmente..."
    echo ""
    echo "🔧 Ejecutando comando de respaldo:"
    echo "   bash /tmp/proxmox-auto-install.sh"
    echo ""
    
    # Intentar ejecutar manualmente con entrada desde terminal
    bash /tmp/proxmox-auto-install.sh < /dev/tty
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ ¡Proceso completado exitosamente con comando manual!"
    else
        echo ""
        echo "❌ Error: El script no pudo ejecutarse correctamente"
        echo ""
        echo "🛠️  SOLUCIÓN MANUAL:"
        echo "   1. Ejecuta: bash /tmp/proxmox-auto-install.sh"
        echo "   2. O descarga de nuevo: wget https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/proxmox-auto-install.sh"
        echo "   3. Y ejecuta: bash proxmox-auto-install.sh"
        echo ""
        echo "📞 Si el problema persiste, reporta el error en:"
        echo "   https://github.com/MondoBoricua/proxmox-duckdns/issues"
        exit 1
    fi
fi

# Limpiar
rm -f /tmp/proxmox-auto-install.sh 