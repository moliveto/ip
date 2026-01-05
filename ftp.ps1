#!/usr/bin/env pwsh
# --- Config / Parameters ---
param(
    [string]$BasePath = $null,
    [switch]$UseGitHub,
    [switch]$DryRun,
    [string]$Branch = $null
)

# Compute defaults for BasePath and Branch (avoid complex expressions in param defaults)
if (-not $BasePath) {
    if ($PSScriptRoot) { $BasePath = $PSScriptRoot } else { $BasePath = (Get-Location).Path }
}
if (-not $Branch) { $Branch = if ($env:GITHUB_BRANCH) { $env:GITHUB_BRANCH } else { 'gh-pages' } }

$basePath = $BasePath
# Guardar y servir siempre el fichero local 'index.html' para que el estado local esté actualizado
$pidFile = Join-Path $basePath "ftp.pid"
$htmlFile = Join-Path $basePath "index.html"

# Leer credenciales desde variables de entorno si están definidas
$ftpHost = if ($env:FTP_HOST) { $env:FTP_HOST } else { "example.com.ar" }
$ftpUser = if ($env:FTP_USER) { $env:FTP_USER } else { "tuUser" }
$ftpPass = if ($env:FTP_PASS) { $env:FTP_PASS } else { "tuPass" }
$remotePath = if ($env:FTP_REMOTE_PATH) { $env:FTP_REMOTE_PATH } else { "/example.com.ar/direccionIp/index.html" }

# GitHub repo info (used if GITHUB_TOKEN present or -UseGitHub passed)
$ghOwner = if ($env:GITHUB_OWNER) { $env:GITHUB_OWNER } else { $null }
$ghRepo = if ($env:GITHUB_REPO) { $env:GITHUB_REPO }  else { $null }


# --- IP previa ---
$IP1 = if (Test-Path $pidFile) { (Get-Content $pidFile -Raw).Trim() } else { "" }

# --- IP pública ---
$IP2 = ""
try { $IP2 = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim() } catch {}
if (-not $IP2) { return }

if ($IP1 -eq $IP2) {
    Write-Output "Iguales: $IP2"
    return
}

# --- Generar HTML ---
$htmlContent = @"
<html><body><h1>$IP2</h1></body></html>
"@
Set-Content -Path $htmlFile -Value $htmlContent -Encoding UTF8
Set-Content -Path $pidFile  -Value $IP2

# --- Decide método de publicación: GitHub API (recomendado) o FTP ---
$published = $false

# Si pediste explícitamente GitHub o hay un token disponible, intentar GitHub API
if ($UseGitHub -or ($env:GITHUB_TOKEN -and $ghOwner -and $ghRepo)) {
    if (-not $env:GITHUB_TOKEN) {
        Write-Warning "GITHUB_TOKEN no está definido en el entorno; no se puede publicar en GitHub."
    }
    else {
        try {
            if ($DryRun) {
                Write-Output "[DRY RUN] GitHub: actualizar '$owner/$repo/$pathInRepo' en branch '$Branch' con contenido (longitud: $($content.Length) chars)."
                $published = $true
            }
            else {
                $owner = $ghOwner
                $repo = $ghRepo
                $pathInRepo = "index.html"

                $content = Get-Content -Path $htmlFile -Raw
                $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))

                $headers = @{ Authorization = "token $($env:GITHUB_TOKEN)"; Accept = "application/vnd.github.v3+json" }
                $fileUrl = "https://api.github.com/repos/$owner/$repo/contents/$pathInRepo?ref=$Branch"
                $sha = $null
                try {
                    $resp = Invoke-RestMethod -Uri $fileUrl -Headers $headers -Method Get -ErrorAction Stop
                    $sha = $resp.sha
                }
                catch {
                    # si no existe, seguimos sin sha
                }

                $body = @{ message = "Update IP via script: $IP2"; content = $base64; branch = $Branch }
                if ($sha) { $body.sha = $sha }

                Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/contents/$pathInRepo" -Headers $headers -Method Put -Body ($body | ConvertTo-Json -Depth 10) -ErrorAction Stop
                Write-Output "Publicado en GitHub: $owner/$repo/$pathInRepo (branch: $Branch)"
                Remove-Item $htmlFile -Force -ErrorAction SilentlyContinue
                $published = $true
            }
        }
        catch {
            Write-Warning "Error publicando en GitHub: $_"
        }
    }
}

# Si no se publicó en GitHub, intentar FTP (si credenciales están configuradas)
if (-not $published) {
    if ($ftpHost -and $ftpUser -and $ftpPass -and $remotePath) {
        try {
            if ($DryRun) {
                Write-Output "[DRY RUN] FTP: subir '$htmlFile' a 'ftp://$ftpHost$remotePath' como usuario '$ftpUser' (PASV)."
                $published = $true
            }
            else {
                $uri = "ftp://$ftpHost$remotePath"
                $ftp = [System.Net.FtpWebRequest]::Create($uri)
                $ftp.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)
                $ftp.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
                $ftp.UseBinary = $true
                $ftp.UsePassive = $true
                $ftp.KeepAlive = $false

                $fileBytes = [System.IO.File]::ReadAllBytes($htmlFile)
                $ftpStream = $ftp.GetRequestStream()
                $ftpStream.Write($fileBytes, 0, $fileBytes.Length)
                $ftpStream.Close()

                Remove-Item $htmlFile -Force -ErrorAction SilentlyContinue
                Write-Output "Actualizado con PASV (FTP)"
                $published = $true
            }
        }
        catch {
            Write-Warning "Error subiendo por FTP: $_"
        }
    }
    else {
        Write-Warning "No hay credenciales FTP configuradas; no se pudo subir por FTP."
    }
}

if (-not $published) {
    Write-Warning "No se publicó la IP: revisa configuraciones FTP o GITHUB_TOKEN/GITHUB_OWNER/GITHUB_REPO."
}
