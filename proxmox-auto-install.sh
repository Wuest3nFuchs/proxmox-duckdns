#!/usr/bin/env bash

# Script de instalación automática de DuckDNS en Proxmox
# Se ejecuta desde el host Proxmox y crea todo automáticamente
# ¡Brutal! - Todo automatizado para la comunidad boricua

# Configuración básica sin manejo estricto de errores

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

echo -n "Token de DuckDNS: "
read DUCKDNS_TOKEN

echo -n "Subdominio (ej. midominio): "
read DUCKDNS_DOMAIN

echo -n "ID del contenedor (ej. 100): "
read CONTAINER_ID

echo -n "Hostname del contenedor [duckdns]: "
read CONTAINER_HOSTNAME
CONTAINER_HOSTNAME=${CONTAINER_HOSTNAME:-duckdns}

echo -n "Contraseña root del contenedor [duckdns]: "
read CONTAINER_PASSWORD
CONTAINER_PASSWORD=${CONTAINER_PASSWORD:-duckdns}

echo -n "Almacenamiento [local-lvm]: "
read STORAGE
STORAGE=${STORAGE:-local-lvm}

echo -n "Bridge de red [vmbr0]: "
read NETWORK_BRIDGE
NETWORK_BRIDGE=${NETWORK_BRIDGE:-vmbr0}

# Validar entradas críticas
if [ -z "$DUCKDNS_TOKEN" ]; then
    show_error "El token de DuckDNS es obligatorio"
    exit 1
fi

if [ -z "$DUCKDNS_DOMAIN" ]; then
    show_error "El subdominio de DuckDNS es obligatorio"
    exit 1
fi

if [ -z "$CONTAINER_ID" ]; then
    show_error "El ID del contenedor es obligatorio"
    exit 1
fi

# Configuración por defecto
CONTAINER_MEMORY=${CONTAINER_MEMORY:-512}
CONTAINER_DISK=${CONTAINER_DISK:-2}
CONTAINER_CORES=${CONTAINER_CORES:-1}
TEMPLATE_NAME="ubuntu-22.04-standard"

show_info "Buscando templates disponibles..."
# Mostrar templates disponibles para referencia
echo "📋 Templates disponibles en el sistema:"
pct template list | head -10

# Buscar templates disponibles en orden de preferencia
TEMPLATE=""

# Primero intentar Ubuntu 22.04
TEMPLATE=$(pct template list | grep -i ubuntu | grep -E "(22\.04|22-04)" | head -1 | awk '{print $2}')
if [ -n "$TEMPLATE" ]; then
    show_success "✅ Usando template de Ubuntu 22.04: $TEMPLATE"
else
    # Si no hay Ubuntu, buscar Debian 12
    TEMPLATE=$(pct template list | grep -i debian | grep -E "(12|12\.)" | head -1 | awk '{print $2}')
    if [ -n "$TEMPLATE" ]; then
        show_success "✅ Usando template de Debian 12: $TEMPLATE"
        show_info "💡 Nota: Se está usando Debian 12 porque Ubuntu 22.04 no está disponible"
    else
        # Buscar cualquier template de Ubuntu o Debian reciente
        TEMPLATE=$(pct template list | grep -iE "(ubuntu|debian)" | head -1 | awk '{print $2}')
        if [ -n "$TEMPLATE" ]; then
            show_success "✅ Usando template disponible: $TEMPLATE"
            show_info "💡 Nota: Se está usando el template más reciente disponible"
        else
            # Si no hay ninguno, descargar Ubuntu 22.04
            show_info "⬇️ No se encontraron templates. Descargando Ubuntu 22.04..."
            pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
            TEMPLATE="ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
            show_success "✅ Template descargado: $TEMPLATE"
        fi
    fi
fi

show_success "Template encontrado: $TEMPLATE"

# Verificar que el ID del contenedor no exista
if pct status $CONTAINER_ID &> /dev/null; then
    show_error "El contenedor ID $CONTAINER_ID ya existe"
    exit 1
fi

show_info "Creando contenedor LXC..."
# Crear el contenedor LXC con autoboot habilitado
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

# Crear el script de actualización de DuckDNS mejorado
run_in_container "cat > /opt/duckdns/duck.sh << 'EOF'
#!/bin/bash
# Script de actualización de DuckDNS - se ejecuta cada 5 minutos
# Mantiene la IP actualizada automáticamente, ¡qué brutal!

# Obtener IP actual
CURRENT_IP=\$(curl -s ifconfig.me 2>/dev/null)
TIMESTAMP=\$(date '+%Y-%m-%d %H:%M:%S')

# Crear directorio de logs si no existe
mkdir -p /var/log/duckdns

# Actualizar DuckDNS
RESULT=\$(echo url=\"https://www.duckdns.org/update?domains=$DUCKDNS_DOMAIN&token=$DUCKDNS_TOKEN&ip=\" | curl -k -s -K -)

# Guardar resultado en log principal
echo \"\$RESULT\" > ~/duckdns.log

# Guardar log detallado
echo \"[\$TIMESTAMP] IP: \$CURRENT_IP - Resultado: \$RESULT\" >> /var/log/duckdns/detailed.log

# Mantener solo las últimas 100 líneas del log detallado
tail -n 100 /var/log/duckdns/detailed.log > /var/log/duckdns/detailed.log.tmp
mv /var/log/duckdns/detailed.log.tmp /var/log/duckdns/detailed.log
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

# Crear script de información avanzado dentro del contenedor
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

# Crear script de bienvenida que se ejecuta al hacer login
run_in_container "cat > /opt/duckdns/welcome.sh << 'EOF'
#!/bin/bash

# Colores para la salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e \"${BLUE}\"
echo \"🦆 ===== DUCKDNS LXC CONTAINER =====\"
echo -e \"${NC}\"

# Información del dominio
echo -e \"${GREEN}🌐 Dominio:${NC} $DUCKDNS_DOMAIN.duckdns.org\"

# Obtener IP actual del servidor
CURRENT_IP=\$(curl -s ifconfig.me 2>/dev/null || echo \"No disponible\")
echo -e \"${GREEN}📡 IP Actual del Servidor:${NC} \$CURRENT_IP\"

# Verificar última actualización
if [ -f ~/duckdns.log ]; then
    LAST_UPDATE=\$(stat -c %y ~/duckdns.log 2>/dev/null | cut -d. -f1)
    LAST_RESULT=\$(cat ~/duckdns.log 2>/dev/null)
    
    echo -e \"${GREEN}🕐 Última Actualización:${NC} \$LAST_UPDATE\"
    
    if [[ \"\$LAST_RESULT\" == *\"OK\"* ]]; then
        echo -e \"${GREEN}✅ Estado:${NC} Actualización exitosa\"
    elif [[ \"\$LAST_RESULT\" == *\"KO\"* ]]; then
        echo -e \"${RED}❌ Estado:${NC} Error en la actualización\"
    else
        echo -e \"${YELLOW}⚠️  Estado:${NC} Resultado desconocido: \$LAST_RESULT\"
    fi
    
    # Mostrar historial de las últimas 3 actualizaciones
    if [ -f /var/log/duckdns/detailed.log ]; then
        echo -e \"${BLUE}📈 Últimas actualizaciones:${NC}\"
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
    echo -e \"${YELLOW}⚠️  Estado:${NC} No hay actualizaciones registradas\"
fi

# Verificar si cron está funcionando
if systemctl is-active --quiet cron; then
    echo -e \"${GREEN}🔄 Servicio Cron:${NC} Activo (actualiza cada 5 minutos)\"
else
    echo -e \"${RED}❌ Servicio Cron:${NC} Inactivo\"
fi

# Verificar resolución DNS
DNS_IP=\$(nslookup $DUCKDNS_DOMAIN.duckdns.org 2>/dev/null | grep -A1 \"Name:\" | grep \"Address:\" | awk '{print \$2}' | head -1)
if [ -n \"\$DNS_IP\" ]; then
    echo -e \"${GREEN}🔍 DNS Resuelve a:${NC} \$DNS_IP\"
    if [ \"\$DNS_IP\" = \"\$CURRENT_IP\" ]; then
        echo -e \"${GREEN}✅ DNS Sincronizado:${NC} IP coincide\"
    else
        echo -e \"${YELLOW}⚠️  DNS Desactualizado:${NC} IP no coincide\"
    fi
else
    echo -e \"${RED}❌ DNS:${NC} No se pudo resolver el dominio\"
fi

echo \"\"
echo -e \"${BLUE}📋 Comandos útiles:${NC}\"
echo \"  • Ver logs en tiempo real: tail -f ~/duckdns.log\"
echo \"  • Ver historial completo: tail -f /var/log/duckdns/detailed.log\"
echo \"  • Actualizar ahora: /opt/duckdns/duck.sh\"
echo \"  • Ver info completa: /root/duckdns-info.sh\"
echo \"  • Estado cron: systemctl status cron\"
echo \"  • Mostrar esta info: duckdns\"
echo \"\"
echo -e \"${BLUE}🚀 Desarrollado con ❤️ para la comunidad de Proxmox${NC}\"
echo \"\"
EOF"

run_in_container "chmod +x /opt/duckdns/welcome.sh"

# Agregar el script de bienvenida al .bashrc para que se ejecute al hacer login
run_in_container "echo '' >> /root/.bashrc"
run_in_container "echo '# Mostrar información de DuckDNS al hacer login' >> /root/.bashrc"
run_in_container "echo '/opt/duckdns/welcome.sh' >> /root/.bashrc"

# También crear un alias para mostrar la info rápidamente
run_in_container "echo 'alias duckdns=\"/opt/duckdns/welcome.sh\"' >> /root/.bashrc"

show_info "Configurando autologin para la consola..."
# Configurar autologin en la consola del contenedor
run_in_container "mkdir -p /etc/systemd/system/console-getty.service.d"
run_in_container "cat > /etc/systemd/system/console-getty.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF"

# Habilitar el servicio de autologin
run_in_container "systemctl daemon-reload"
run_in_container "systemctl enable console-getty.service"

# También configurar autologin para tty1 (consola principal)
run_in_container "mkdir -p /etc/systemd/system/getty@tty1.service.d"
run_in_container "cat > /etc/systemd/system/getty@tty1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF"

run_in_container "systemctl daemon-reload"

show_success "¡Instalación completada exitosamente!"
echo ""
echo "🎉 ===== RESUMEN DE LA INSTALACIÓN ====="
echo "📦 Contenedor ID: $CONTAINER_ID"
echo "🏷️  Hostname: $CONTAINER_HOSTNAME"
echo "🌐 Dominio: $DUCKDNS_DOMAIN.duckdns.org"
echo "🔑 Contraseña root: $CONTAINER_PASSWORD"
echo "💾 Almacenamiento: $STORAGE"
echo "🔧 Red: $NETWORK_BRIDGE"
echo "🚀 Autoboot: Habilitado"
echo "🔓 Autologin: Habilitado (consola automática)"
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
echo "✅ CARACTERÍSTICAS HABILITADAS:"
echo "• ✅ DuckDNS configurado y funcionando automáticamente"
echo "• ✅ Actualización de IP cada 5 minutos"
echo "• ✅ Autoboot al iniciar Proxmox"
echo "• ✅ Autologin en consola (sin contraseña)"
echo "• ✅ Pantalla de bienvenida con información en tiempo real"
echo ""
echo "💡 NOTA: Al entrar por consola (no SSH), no necesitas contraseña"
echo "Para SSH usa: ssh root@IP_DEL_CONTENEDOR (contraseña: $CONTAINER_PASSWORD)"
echo ""
echo "🚀 ¡Desarrollado con ❤️ para la comunidad de Proxmox!" 