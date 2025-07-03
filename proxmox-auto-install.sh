#!/usr/bin/env bash

# Script de instalación automática de DuckDNS en Proxmox
# Se ejecuta desde el host Proxmox y crea todo automáticamente
# ¡Brutal! - Todo automatizado para la comunidad boricua

set -e  # Salir si hay algún error

echo "🦆 ===== INSTALADOR AUTOMÁTICO DUCKDNS PARA PROXMOX ====="
echo "Este script va a crear un contenedor LXC y configurar DuckDNS automáticamente"
echo ""

# Función para mostrar mensajes con colores
show_info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}

show_success() {
    echo -e "\e[32m[OK]\e[0m $1"
}

show_error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

# Verificar que estamos en Proxmox
if ! command -v pct &> /dev/null; then
    show_error "Este script debe ejecutarse en un servidor Proxmox VE"
    exit 1
fi

# Pedir información al usuario
echo "📝 Configuración inicial:"
read -r -p "Token de DuckDNS: " DUCKDNS_TOKEN
read -r -p "Subdominio (ej. midominio): " DUCKDNS_DOMAIN
read -r -p "ID del contenedor (ej. 100): " CONTAINER_ID
read -r -p "Hostname del contenedor (ej. duckdns): " CONTAINER_HOSTNAME
read -r -p "Contraseña root del contenedor: " CONTAINER_PASSWORD
read -r -p "Almacenamiento (ej. local-lvm): " STORAGE
read -r -p "Bridge de red (ej. vmbr0): " NETWORK_BRIDGE

# Configuración por defecto
CONTAINER_MEMORY=${CONTAINER_MEMORY:-512}
CONTAINER_DISK=${CONTAINER_DISK:-2}
CONTAINER_CORES=${CONTAINER_CORES:-1}
TEMPLATE_NAME="ubuntu-22.04-standard"

show_info "Buscando template de Ubuntu..."
# Buscar el template disponible
TEMPLATE=$(pct template list | grep -i ubuntu | grep -i 22.04 | head -1 | awk '{print $2}')
if [ -z "$TEMPLATE" ]; then
    show_error "No se encontró template de Ubuntu 22.04"
    show_info "Descargando template de Ubuntu 22.04..."
    pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
    TEMPLATE="ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
fi

show_success "Template encontrado: $TEMPLATE"

# Verificar que el ID del contenedor no exista
if pct status $CONTAINER_ID &> /dev/null; then
    show_error "El contenedor ID $CONTAINER_ID ya existe"
    exit 1
fi

show_info "Creando contenedor LXC..."
# Crear el contenedor LXC
pct create $CONTAINER_ID local:vztmpl/$TEMPLATE \
    --hostname $CONTAINER_HOSTNAME \
    --memory $CONTAINER_MEMORY \
    --cores $CONTAINER_CORES \
    --rootfs $STORAGE:$CONTAINER_DISK \
    --net0 name=eth0,bridge=$NETWORK_BRIDGE,ip=dhcp \
    --password $CONTAINER_PASSWORD \
    --start 1 \
    --unprivileged 1 \
    --features nesting=1

show_success "Contenedor $CONTAINER_ID creado exitosamente"

# Esperar a que el contenedor esté listo
show_info "Esperando a que el contenedor esté listo..."
sleep 30

# Función para ejecutar comandos en el contenedor
run_in_container() {
    pct exec $CONTAINER_ID -- bash -c "$1"
}

show_info "Actualizando sistema en el contenedor..."
# Actualizar el sistema
run_in_container "apt update && apt upgrade -y"

show_info "Instalando dependencias..."
# Instalar dependencias
run_in_container "apt install -y curl cron wget"

show_info "Configurando DuckDNS..."
# Crear directorio para DuckDNS
run_in_container "mkdir -p /opt/duckdns"

# Crear el script de actualización de DuckDNS
run_in_container "cat > /opt/duckdns/duck.sh << 'EOF'
#!/bin/bash
# Script de actualización de DuckDNS - se ejecuta cada 5 minutos
# Mantiene la IP actualizada automáticamente, ¡qué brutal!
echo url=\"https://www.duckdns.org/update?domains=$DUCKDNS_DOMAIN&token=$DUCKDNS_TOKEN&ip=\" | curl -k -o ~/duckdns.log -K -
EOF"

# Dar permisos al script
run_in_container "chmod 700 /opt/duckdns/duck.sh"

show_info "Configurando cron para actualización automática..."
# Configurar cron para ejecutar cada 5 minutos
run_in_container "cat > /etc/cron.d/duckdns << 'EOF'
*/5 * * * * root /opt/duckdns/duck.sh >/dev/null 2>&1
EOF"

# Configurar permisos de cron
run_in_container "chmod 644 /etc/cron.d/duckdns"

# Reiniciar cron
run_in_container "systemctl restart cron"

show_info "Probando primera actualización..."
# Ejecutar una primera actualización
run_in_container "/opt/duckdns/duck.sh"

# Verificar el resultado
RESULT=$(run_in_container "cat ~/duckdns.log 2>/dev/null || echo 'No log found'")
if [[ "$RESULT" == *"OK"* ]]; then
    show_success "Primera actualización exitosa: $RESULT"
else
    show_error "Posible error en la actualización: $RESULT"
fi

show_info "Limpiando sistema..."
# Limpiar sistema
run_in_container "apt autoremove -y && apt autoclean"

# Crear script de información dentro del contenedor
run_in_container "cat > /root/duckdns-info.sh << 'EOF'
#!/bin/bash
echo \"🦆 ===== INFORMACIÓN DUCKDNS =====\"
echo \"Dominio: $DUCKDNS_DOMAIN.duckdns.org\"
echo \"Estado del servicio cron:\"
systemctl status cron --no-pager -l
echo \"\"
echo \"Última actualización:\"
cat ~/duckdns.log 2>/dev/null || echo \"No hay log disponible\"
echo \"\"
echo \"Para ver logs en tiempo real: tail -f ~/duckdns.log\"
echo \"Para actualizar manualmente: /opt/duckdns/duck.sh\"
EOF"

run_in_container "chmod +x /root/duckdns-info.sh"

show_success "¡Instalación completada exitosamente!"
echo ""
echo "🎉 ===== RESUMEN DE LA INSTALACIÓN ====="
echo "📦 Contenedor ID: $CONTAINER_ID"
echo "🏷️  Hostname: $CONTAINER_HOSTNAME"
echo "🌐 Dominio: $DUCKDNS_DOMAIN.duckdns.org"
echo "💾 Almacenamiento: $STORAGE"
echo "🔧 Red: $NETWORK_BRIDGE"
echo ""
echo "📋 COMANDOS ÚTILES:"
echo "• Acceder al contenedor: pct enter $CONTAINER_ID"
echo "• Ver información: pct exec $CONTAINER_ID -- /root/duckdns-info.sh"
echo "• Parar contenedor: pct stop $CONTAINER_ID"
echo "• Iniciar contenedor: pct start $CONTAINER_ID"
echo ""
echo "🔍 VERIFICACIÓN:"
echo "• Verifica tu dominio: nslookup $DUCKDNS_DOMAIN.duckdns.org"
echo "• IP actual: curl -s ifconfig.me"
echo ""
echo "✅ DuckDNS está configurado y funcionando automáticamente"
echo "El contenedor actualizará tu IP cada 5 minutos"
echo ""
echo "🚀 ¡Desarrollado con ❤️ para la comunidad de Proxmox!" 