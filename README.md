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
