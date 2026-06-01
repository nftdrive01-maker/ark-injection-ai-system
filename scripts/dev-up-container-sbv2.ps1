param(
    [switch]$Build,
    [switch]$IncludeGoogleWorkspaceMcp,
    [switch]$IncludeEstatMcp,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

$composeFiles = @(
    '-f', (Join-Path $repoRoot 'docker-compose.yml'),
    '-f', (Join-Path $repoRoot 'docker-compose.dev.yml')
)

$command = @(
    'up',
    '-d'
)

if ($Build) {
    $command += '--build'
}

$command += @(
    'amica',
    'injection-tool',
    'mcp-server',
    'sbv2'
)

if ($IncludeGoogleWorkspaceMcp) {
    $command += 'google-workspace-mcp'
}

if ($IncludeEstatMcp) {
    $command += 'estat-mcp'
}

Write-Host 'Starting docker compose with sbv2-init + sbv2 (container SBV2 mode).'
Write-Host 'Use SBV2_DEVICE in .env to switch cpu / cuda.'
Write-Host 'google-workspace-mcp / estat-mcp are optional and start only when explicitly included.'

if ($DryRun) {
    Write-Host ('DRY RUN: docker-compose ' + (($composeFiles + $command) -join ' '))
    return
}

& docker-compose @composeFiles @command