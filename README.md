## Configuración de variables de entorno

> **⚠️ Seguridad:** nunca publiques tu `GITHUB_TOKEN` en el repositorio ni en capturas de pantalla.

### Linux / macOS (bash/zsh)

```bash
export GITHUB_OWNER="tu-usuario"
export GITHUB_REPO="mi-ip"
export GITHUB_BRANCH="main"
export GITHUB_TOKEN="ghp_xxx..."
```

### Windows

```bash
$env:GITHUB_OWNER=""
$env:GITHUB_REPO=""
$env:GITHUB_BRANCH=""
$env:GITHUB_TOKEN=""
```

node .\publish-ip.js

## Ejecutar con un clic en Windows (PowerShell)

> **Nota:** La extensión correcta para scripts de PowerShell es **`.ps1`** (no `.ps`, que suele abrirse con GIMP u otros).

1. **Crear `environment.ps1`** (no lo subas al repo) con tus valores y la ejecución del publicador:

   ```powershell
   # environment.ps1
   # ⚠️ Mantén este archivo fuera del control de versiones
   $env:GITHUB_OWNER  = "tu-usuario"
   $env:GITHUB_REPO   = "mi-ip"
   $env:GITHUB_BRANCH = "main"
   $env:GITHUB_TOKEN  = "ghp_xxx..."   # secreto

   # Ejecuta el publicador desde la misma carpeta del script
   node "$PSScriptRoot\publish-ip.js"
