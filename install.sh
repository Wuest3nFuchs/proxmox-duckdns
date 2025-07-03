#!/usr/bin/env bash

# Instalador rápido de DuckDNS para Proxmox LXC
# Este script descarga y ejecuta el instalador principal

echo "🦆 Instalador Rápido de DuckDNS para Proxmox LXC"
echo "================================================"

# Verificamos que estamos ejecutando como root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Este script debe ejecutarse como root (sudo)"
   exit 1
fi

# Verificamos que tenemos wget o curl disponible
if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    echo "📦 Instalando wget..."
    apt update && apt install -y wget
fi

# URL del script principal
SCRIPT_URL="https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/duckdns.sh"

echo "⬇️  Descargando instalador..."

# Descargamos el script principal
if command -v wget &> /dev/null; then
    wget -O /tmp/duckdns.sh "$SCRIPT_URL"
else
    curl -o /tmp/duckdns.sh "$SCRIPT_URL"
fi

# Verificamos que se descargó correctamente
if [[ ! -f /tmp/duckdns.sh ]]; then
    echo "❌ Error al descargar el script"
    exit 1
fi

# Le damos permisos de ejecución
chmod +x /tmp/duckdns.sh

echo "🚀 Ejecutando instalador..."
echo ""

# Ejecutamos el script principal
/tmp/duckdns.sh

# Limpiamos el archivo temporal
rm -f /tmp/duckdns.sh

echo ""
echo "✅ Instalación completada!"
echo "Tu DuckDNS ya está configurado y funcionando 🎉" 