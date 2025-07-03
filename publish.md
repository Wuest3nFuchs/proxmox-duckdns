# 📝 Guía para Publicar en GitHub

## Paso 1: Crear el Repositorio en GitHub

1. Ve a [GitHub.com](https://github.com)
2. Haz clic en "New repository" (botón verde)
3. Nombre sugerido: `proxmox-duckdns`
4. Descripción: "Script automatizado para configurar DuckDNS en contenedores LXC de Proxmox"
5. Marca como **público**
6. **NO** marques "Add a README file" (ya tenemos uno)
7. Haz clic en "Create repository"

## Paso 2: Comandos para Publicar

Ejecuta estos comandos en tu terminal (dentro del directorio del proyecto):

```bash
# Inicializar git (si no está inicializado)
git init

# Agregar todos los archivos
git add .

# Hacer el primer commit
git commit -m "🦆 Inicial: Script DuckDNS para Proxmox LXC con instalador automático"

# Agregar el remote de GitHub (reemplaza TU_USUARIO con tu usuario de GitHub)
git remote add origin https://github.com/TU_USUARIO/proxmox-duckdns.git

# Cambiar a la rama main
git branch -M main

# Subir los archivos a GitHub
git push -u origin main
```

## Paso 3: Actualizar URLs en los Archivos

Después de crear el repositorio, actualiza estos archivos con tu información:

### En `README.md`:
- Busca `[TU_USUARIO]/[TU_REPO]` y reemplaza con tu usuario/repo real
- Ejemplo: `tu-usuario/proxmox-duckdns`

### En `install.sh`:
- Busca `TU_USUARIO/proxmox-duckdns` y reemplaza con tu usuario/repo real

## Paso 4: Hacer el Segundo Commit

```bash
# Agregar los cambios
git add README.md install.sh

# Hacer commit con las URLs actualizadas
git commit -m "📝 Actualizar URLs del repositorio"

# Subir los cambios
git push
```

## Paso 5: Crear un Release (Opcional)

1. Ve a tu repositorio en GitHub
2. Haz clic en "Releases"
3. Haz clic en "Create a new release"
4. Tag: `v1.0.0`
5. Título: `🦆 DuckDNS para Proxmox LXC v1.0.0`
6. Descripción: Primera versión estable del instalador automático
7. Haz clic en "Publish release"

## 🎉 ¡Listo!

Tu proyecto estará disponible en:
- **Repositorio**: `https://github.com/TU_USUARIO/proxmox-duckdns`
- **Instalación rápida**: `curl -sSL https://raw.githubusercontent.com/TU_USUARIO/proxmox-duckdns/main/install.sh | sudo bash`

## 📋 Archivos Creados

- `duckdns.sh` - Script principal con comentarios en español
- `install.sh` - Instalador rápido de una línea
- `README.md` - Documentación completa
- `LICENSE` - Licencia MIT
- `.gitignore` - Archivos a ignorar
- `.github/workflows/test.yml` - Tests automáticos
- `publish.md` - Esta guía de publicación 