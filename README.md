# Publicar tu IP en GitHub Pages / FTP

Este repositorio contiene scripts para publicar la IP pública de tu máquina en una página (GitHub Pages) o subiéndola por FTP.

⚠️ Seguridad: nunca pongas tu `GITHUB_TOKEN` ni credenciales en archivos versionados. Usa `environment.ps1` local, variables de entorno o un gestor de secretos.

## Contenido principal

- `ftp.ps1` — genera `index.html` con la IP y puede publicar mediante la GitHub Contents API o por FTP (lee credenciales desde variables de entorno).
- `environment.ps1` — plantilla para definir `GITHUB_OWNER`, `GITHUB_REPO`, `GITHUB_BRANCH` y (opcionalmente) `GITHUB_TOKEN` en tu entorno local. No lo subas al repo.
- `README_GITHUB_TOKEN.md` — resumen sobre cómo gestionar tu `GITHUB_TOKEN` de forma segura.

## Configurar variables de entorno

Linux / macOS (bash/zsh):

```bash
export GITHUB_OWNER="tu-usuario"
export GITHUB_REPO="mi-ip"
export GITHUB_BRANCH="main"
export GITHUB_TOKEN="ghp_xxx..."
```

Windows (PowerShell, temporal en la sesión):

```powershell
$env:GITHUB_OWNER = "tu-usuario"
$env:GITHUB_REPO  = "mi-ip"
$env:GITHUB_BRANCH = "main"
$env:GITHUB_TOKEN = "ghp_xxx..."
```

Para CI (GitHub Actions) añade el token como secret en: Repo → Settings → Secrets and variables → Actions → New repository secret y úsalo como `${{ secrets.PAT_GITHUB }}`.

## Guardar el token de forma segura (recomendado en Windows)

Usa PowerShell SecretManagement + SecretStore:

```powershell
Install-Module Microsoft.PowerShell.SecretManagement -Repository PSGallery -Force -Scope CurrentUser
Install-Module Microsoft.PowerShell.SecretStore -Repository PSGallery -Force -Scope CurrentUser
Register-SecretVault -Name MyVault -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
Set-Secret -Name "GITHUB_TOKEN" -Secret (Read-Host "PAT (pega aquí)" -AsSecureString)
# Recuperar en scripts sin exponarlo en logs:
$env:GITHUB_TOKEN = Get-Secret -Name "GITHUB_TOKEN" -AsPlainText
```

Alternativas: Windows Credential Manager, 1Password, Bitwarden.

## Usar `ftp.ps1`

Ejemplos:

# Publicar en GitHub (recomendado)

```powershell
. .\environment.ps1   # carga las variables en la sesión (si usas este archivo)
.\ftp.ps1 -UseGitHub
```

# Forzar publicación por FTP (si prefieres FTP y tienes credenciales)

```powershell
$env:FTP_HOST="miftp.com"
$env:FTP_USER="usuario"
$env:FTP_PASS="contraseña"
$env:FTP_REMOTE_PATH="/ruta/index.html"
.\ftp.ps1
```

Parámetros útiles de `ftp.ps1`:

- `-UseGitHub` — forzar intento de publicar usando la API de GitHub
- `-DryRun` — simula la acción sin realizar llamadas de red (útil para pruebas)
- `-BasePath <path>` — especificar carpeta donde escribir `ip.html` y `ftp.pid`

Si el script detecta que la IP no cambió (compara con `ftp.pid`) no hará ninguna publicación. Para forzar publicación elimina `ftp.pid` y vuelve a ejecutar:

```powershell
Remove-Item .\ftp.pid -Force
.\ftp.ps1 -UseGitHub
```

## Buenas prácticas y rotación

- Usa Fine‑grained PATs con el mínimo permiso necesario y expiración corta (30–90 días).
- Rota los tokens periódicamente.
- Si un token se filtra, revócalo inmediatamente en GitHub y crea uno nuevo.

## GitHub Actions

Agrega el secret en el repo y úsalo en tu workflow:

```yaml
env:
   GITHUB_TOKEN: ${{ secrets.PAT_GITHUB }}
steps:
   - uses: actions/checkout@v4
   - name: Publish IP
      run: pwsh -File ./ftp.ps1 -UseGitHub
      env:
         GITHUB_TOKEN: ${{ secrets.PAT_GITHUB }}
```

## Desbloquear archivos PowerShell y política de ejecución (Windows)

```powershell
Unblock-File .\environment.ps1
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Notas finales

No subas `environment.ps1` al repositorio. Usa `environment.ps1.example` como plantilla local.

Para más detalles sobre manejo seguro del token revisa `README_GITHUB_TOKEN.md`.
