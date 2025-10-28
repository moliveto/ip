# --- Config ---
$basePath = if ($PSScriptRoot) { $PSScriptRoot } else { "C:\Users\tuUser\carpetadDeProc" }
$pidFile  = Join-Path $basePath "ftp.pid"
$htmlFile = Join-Path $basePath "ip.html"

$ftpHost  = "example.com.ar"
$ftpUser  = "tuUser"
$ftpPass  = "tuPass"
$remotePath = "/example.com.ar/direccionIp/index.html"   # ruta en tu servidor

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

# --- Subir por FTP en PASV ---
$uri = "ftp://$ftpHost$remotePath"
$ftp = [System.Net.FtpWebRequest]::Create($uri)
$ftp.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)
$ftp.Method      = [System.Net.WebRequestMethods+Ftp]::UploadFile
$ftp.UseBinary   = $true
$ftp.UsePassive  = $true
$ftp.KeepAlive   = $false

$fileBytes = [System.IO.File]::ReadAllBytes($htmlFile)
$ftpStream = $ftp.GetRequestStream()
$ftpStream.Write($fileBytes, 0, $fileBytes.Length)
$ftpStream.Close()

Remove-Item $htmlFile -Force

Write-Output "Actualizado con PASV"
