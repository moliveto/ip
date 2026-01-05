# Gestionar GITHUB_TOKEN (resumen)

1. Crear un Personal Access Token (PAT) en GitHub

   - GitHub → Settings → Developer settings → Personal access tokens → Fine‑grained tokens
   - Elegir permisos mínimos y establecer expiración (30–90 días recomendado).

2. Guardar el token localmente (Windows)

   - Recomendado: PowerShell SecretManagement + SecretStore

     - Install-Module Microsoft.PowerShell.SecretManagement -Repository PSGallery -Force
     - Install-Module Microsoft.PowerShell.SecretStore -Repository PSGallery -Force
     - Register-SecretVault -Name MyVault -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
     - Set-Secret -Name "GITHUB_TOKEN" -Secret (Read-Host "PAT" -AsSecureString)
     - Recuperar en scripts: $env:GITHUB_TOKEN = Get-Secret -Name "GITHUB_TOKEN" -AsPlainText

   - Alternativa: Windows Credential Manager o gestor de contraseñas (1Password/Bitwarden).

3. Para CI (GitHub Actions)

   - Repo → Settings → Secrets and variables → Actions → New repository secret
   - Usar el secreto en workflows como: ${{ secrets.PAT_GITHUB }}

4. Si el token se filtra

   - Revocar inmediatamente en GitHub y crear uno nuevo.
   - Para limpiar historial Git, usar herramientas como BFG o git filter-repo (operación destructiva).

5. Buenas prácticas
   - Fine‑grained token, expiración, rotación periódica (ej. cada 90 días), menor privilegio.
   - No subir tokens a repos, issues o chats.
