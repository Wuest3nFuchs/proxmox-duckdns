# 🦆 DuckDNS para Proxmox LXC

Un script automatizado para configurar DuckDNS en contenedores LXC de Proxmox, perfecto para mantener tu IP dinámica actualizada sin complicaciones.

## 📋 Requisitos

- **Proxmox VE** (cualquier versión reciente)
- **Contenedor LXC** con Ubuntu/Debian
- **Token de DuckDNS** (obtenido desde [duckdns.org](https://www.duckdns.org))
- **Subdominio registrado** en DuckDNS

## 🚀 Instalación Rápida

### 1. Crear el Contenedor LXC

En Proxmox, crea un nuevo contenedor LXC:
- **Template**: Ubuntu 22.04 o Debian 11/12
- **RAM**: 512MB (suficiente)
- **Disco**: 2GB (mínimo)
- **Red**: Configurada con acceso a internet

### 2. Acceder al Contenedor

```bash
# Desde Proxmox, accede al contenedor
pct enter [ID_DEL_CONTENEDOR]
```

### 3. Instalación (Método Rápido) 🚀

```bash
# Instalación en una sola línea
curl -sSL https://raw.githubusercontent.com/[TU_USUARIO]/[TU_REPO]/main/install.sh | sudo bash
```

### 3. Instalación (Método Manual)

```bash
# Descargar el script
wget https://raw.githubusercontent.com/[TU_USUARIO]/[TU_REPO]/main/duckdns.sh

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
/etc/cron.d/duckdns           # Configuración de cron
~/duckdns.log                 # Log de actualizaciones
```

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
```

### Verificar DNS
```bash
# Comprobar que tu dominio resuelve correctamente
nslookup tudominio.duckdns.org
```

## 🛠️ Solución de Problemas

### El cron no se ejecuta
```bash
# Reiniciar el servicio cron
systemctl restart cron

# Verificar logs del sistema
journalctl -u cron
```

### El script no actualiza la IP
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

**Desarrollado con ❤️ para la comunidad de Proxmox** 