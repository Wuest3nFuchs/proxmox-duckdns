# 🦆 DuckDNS para Proxmox LXC

Un script automatizado para configurar DuckDNS en contenedores LXC de Proxmox, perfecto para mantener tu IP dinámica actualizada sin complicaciones.

## 📋 Requisitos

- **Proxmox VE** (cualquier versión reciente)
- **Template LXC** (Ubuntu 22.04 o Debian 12 - se detecta automáticamente)
- **Token de DuckDNS** (obtenido desde [duckdns.org](https://www.duckdns.org))
- **Subdominio registrado** en DuckDNS

## 🚀 Instalación Rápida

### Método 1: Instalación Automática Completa (¡RECOMENDADO!) 🎯

**Opción A: Súper Rápida (Dos pasos)** ⚡

```bash
# Paso 1: Descargar el instalador
curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/auto-install.sh | bash

# Paso 2: Ejecutar el instalador (copia y pega el comando que aparece)
bash /tmp/proxmox-auto-install.sh
```

> **💡 Nota**: El primer comando descarga el instalador, el segundo lo ejecuta. Así evitamos problemas con pipes.

**Opción B: Descarga y Ejecuta** 📥

```bash
# Desde el host Proxmox (SSH o consola)
wget https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/proxmox-auto-install.sh
chmod +x proxmox-auto-install.sh
./proxmox-auto-install.sh
```

**¿Qué hace este script?**
- ✅ Crea el contenedor LXC automáticamente
- ✅ Detecta y usa el mejor template disponible (Ubuntu 22.04 o Debian 12)
- ✅ Configura la red y almacenamiento
- ✅ Instala y configura DuckDNS
- ✅ Configura cron para actualización automática
- ✅ Habilita autoboot (se inicia automáticamente con Proxmox)
- ✅ Configura autologin en consola (sin contraseña)
- ✅ Contraseña por defecto: `duckdns` (personalizable)
- ✅ Crea pantalla de bienvenida con información en tiempo real
- ✅ Prueba la primera actualización
- ✅ ¡Todo listo en 5 minutos!

### Método 2: Instalación Manual en Contenedor Existente

#### 1. Crear el Contenedor LXC

En Proxmox, crea un nuevo contenedor LXC:
- **Template**: Ubuntu 22.04 o Debian 11/12
- **RAM**: 512MB (suficiente)
- **Disco**: 2GB (mínimo)
- **Red**: Configurada con acceso a internet

#### 2. Acceder al Contenedor

```bash
# Desde Proxmox, accede al contenedor
pct enter [ID_DEL_CONTENEDOR]
```

#### 3. Instalación (Método Rápido) 🚀

```bash
# Instalación en una sola línea
curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/install.sh | sudo bash
```

#### 3. Instalación (Método Manual)

```bash
# Descargar el script
wget https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/duckdns.sh

# Darle permisos de ejecución
chmod +x duckdns.sh

# Ejecutar como root
sudo ./duckdns.sh
```

### 4. Configurar Durante la Instalación

El script te pedirá:
- **Token de DuckDNS**: Tu token personal de la página de DuckDNS
- **Subdominio**: Solo el nombre (ej: `midominio`, no `midominio.duckdns.org`)

## 🔧 Lo que Hace el Script

El instalador automáticamente:

1. **Instala dependencias** necesarias (`curl` y `cron`)
2. **Crea el directorio** `/opt/duckdns/`
3. **Genera el script** de actualización personalizado
4. **Configura cron** para ejecutar cada 5 minutos
5. **Inicia el servicio** cron automáticamente
6. **Limpia el sistema** removiendo paquetes innecesarios

## 📁 Archivos Creados

Después de la instalación encontrarás:

```
/opt/duckdns/duck.sh          # Script de actualización
/opt/duckdns/welcome.sh       # Pantalla de bienvenida
/etc/cron.d/duckdns           # Configuración de cron
~/duckdns.log                 # Log de actualizaciones
/var/log/duckdns/detailed.log # Historial detallado
```

## 🔓 Acceso al Contenedor

### **Consola Proxmox (Recomendado)**
```bash
# Acceso directo sin contraseña (autologin habilitado)
pct enter [ID_CONTENEDOR]
```

### **SSH (Opcional)**
```bash
# Acceso por SSH (requiere contraseña)
ssh root@IP_DEL_CONTENEDOR
# Contraseña por defecto: duckdns
```

### **Autoboot**
El contenedor se inicia automáticamente cuando Proxmox arranca.

## 🖥️ Pantalla de Bienvenida

Cuando entres al contenedor (`pct enter [ID]`), verás automáticamente:

- 🌐 **Dominio configurado**
- 📡 **IP actual del servidor**
- 🕐 **Última actualización y resultado**
- 📈 **Historial de las últimas 3 actualizaciones**
- 🔄 **Estado del servicio cron**
- 🔍 **Verificación de DNS en tiempo real**
- 📋 **Comandos útiles disponibles**

**Comando rápido**: Escribe `duckdns` en cualquier momento para ver la información.

## 🔍 Verificar que Funciona

### Comprobar el Cron
```bash
# Ver si el cron está activo
systemctl status cron

# Verificar la configuración
cat /etc/cron.d/duckdns
```

### Ejecutar Manualmente
```bash
# Probar el script manualmente
/opt/duckdns/duck.sh

# Ver el resultado
cat ~/duckdns.log

# Ver historial completo
tail -f /var/log/duckdns/detailed.log

# Mostrar información completa
duckdns
```

### Verificar DNS
```bash
# Comprobar que tu dominio resuelve correctamente
nslookup tudominio.duckdns.org
```

## 🛠️ Solución de Problemas

### Problemas con el Instalador Automático

#### Error: "Este script debe ejecutarse en un servidor Proxmox VE"
```bash
# Asegúrate de estar en el HOST Proxmox, no en un contenedor
# Usa SSH para conectarte al servidor Proxmox directamente
ssh root@IP_DE_TU_PROXMOX
```

#### El instalador automático no funciona
```bash
# Solución 1: Usar el método de dos pasos
curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/auto-install.sh | bash
bash /tmp/proxmox-auto-install.sh

# Solución 2: Descargar y ejecutar paso a paso
wget https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/proxmox-auto-install.sh
chmod +x proxmox-auto-install.sh
./proxmox-auto-install.sh
```

#### El autologin no funciona
```bash
# Arreglar autologin en contenedor existente
wget https://raw.githubusercontent.com/MondoBoricua/proxmox-duckdns/main/fix-autologin.sh
chmod +x fix-autologin.sh
./fix-autologin.sh [ID_CONTENEDOR]

# O manualmente:
pct reboot [ID_CONTENEDOR]
```

#### El contenedor no se crea
```bash
# Verifica que el ID no esté en uso
pct list

# Verifica que el storage existe
pvesm status

# Verifica templates disponibles
pct template list
```

#### Error de permisos o red
```bash
# Verifica la configuración de red
ip addr show

# Verifica el bridge de red
brctl show
```

### Problemas Generales

#### El cron no se ejecuta
```bash
# Reiniciar el servicio cron
systemctl restart cron

# Verificar logs del sistema
journalctl -u cron
```

#### El script no actualiza la IP
```bash
# Verificar conectividad
curl -I https://www.duckdns.org

# Comprobar el token y dominio en el script
cat /opt/duckdns/duck.sh
```

### Cambiar la frecuencia de actualización
```bash
# Editar el archivo de cron (por defecto cada 5 minutos)
nano /etc/cron.d/duckdns

# Ejemplos de frecuencias:
# */1 * * * *     # Cada minuto
# */10 * * * *    # Cada 10 minutos  
# 0 */1 * * *     # Cada hora
```

## 🔄 Desinstalar

Si necesitas remover DuckDNS:

```bash
# Detener y remover cron
rm /etc/cron.d/duckdns
systemctl restart cron

# Eliminar archivos
rm -rf /opt/duckdns/
rm ~/duckdns.log
```

## 📝 Notas Importantes

- **Compatibilidad**: Funciona con Ubuntu 22.04 y Debian 12 (detección automática)
- **Templates**: El script busca automáticamente el mejor template disponible
- **Autologin**: La consola de Proxmox no requiere contraseña (configurado automáticamente)
- **Contraseña SSH**: Por defecto es `duckdns` (puedes cambiarla durante la instalación)
- **Autoboot**: El contenedor se inicia automáticamente con Proxmox
- **Seguridad**: El script se ejecuta como root, asegúrate de confiar en el código
- **Logs**: Los logs se guardan en `~/duckdns.log` para debugging
- **Firewall**: No necesitas abrir puertos adicionales
- **Backup**: Considera respaldar tu configuración antes de cambios mayores

## 🤝 Contribuir

¿Encontraste un bug o tienes una mejora? 
1. Haz fork del repositorio
2. Crea tu rama de feature (`git checkout -b feature/mejora-increible`)
3. Commit tus cambios (`git commit -am 'Añade mejora increíble'`)
4. Push a la rama (`git push origin feature/mejora-increible`)
5. Crea un Pull Request

## 📜 Licencia

Este proyecto está bajo la Licencia MIT - ve el archivo [LICENSE](LICENSE) para más detalles.

## ⭐ ¿Te Sirvió?

Si este script te ayudó, ¡dale una estrella al repo! ⭐

---

**Desarrollado en 🇵🇷 Puerto Rico con mucho ☕ café ❤️ para la comunidad de Proxmox**