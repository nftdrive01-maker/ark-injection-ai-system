$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$certDir = Join-Path $root '.certs'
if (-not (Test-Path $certDir)) {
  New-Item -ItemType Directory -Path $certDir | Out-Null
}

$certFile = Join-Path $certDir 'amica-local.pem'
$keyFile = Join-Path $certDir 'amica-local-key.pem'

$ips = Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } |
  Select-Object -ExpandProperty IPAddress -Unique

$hosts = @('localhost','127.0.0.1') + $ips + @('amica.local')

$mkcert = Get-Command mkcert -ErrorAction SilentlyContinue
if (-not $mkcert) {
  Write-Host 'mkcert が見つかりません。先に以下を実行してください:' -ForegroundColor Yellow
  Write-Host '  winget install FiloSottile.mkcert' -ForegroundColor Yellow
  Write-Host '  mkcert -install' -ForegroundColor Yellow
  exit 1
}

& mkcert -install | Out-Host
& mkcert -cert-file $certFile -key-file $keyFile @hosts | Out-Host

Write-Host ''
Write-Host '証明書作成完了:' -ForegroundColor Green
Write-Host "  $certFile"
Write-Host "  $keyFile"
Write-Host ''
Write-Host '次の起動コマンド:' -ForegroundColor Cyan
Write-Host '  docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.lan-https.yml up -d amica-https'
