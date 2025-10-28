$url = "https://moliveto.github.io/ip/"
$content = Invoke-RestMethod -Uri $url -UseBasicParsing
# Si viene como HTML, usamos regex para encontrar la IP
if ($content -match '\d{1,3}(\.\d{1,3}){3}') {
    $matches[0]
}
else {
    Write-Error "No se encontró una dirección IP en la respuesta."
}
