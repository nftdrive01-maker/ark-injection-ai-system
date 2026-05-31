param(
    [switch]$RemoveVolumes,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$composeFiles = @(
    '-f', (Join-Path $repoRoot 'docker-compose.yml'),
    '-f', (Join-Path $repoRoot 'docker-compose.dev.yml')
)

$command = @(
    'stop',
    'amica',
    'injection-tool',
    'mcp-server',
    'sbv2'
)

if ($DryRun) {
    Write-Host ('DRY RUN: docker-compose ' + (($composeFiles + $command) -join ' '))
    return
}

& docker-compose @composeFiles @command

if ($RemoveVolumes) {
    $rmCommand = @(
        'rm',
        '-f',
        '-v',
        'amica',
        'injection-tool',
        'mcp-server',
        'sbv2'
    )
    & docker-compose @composeFiles @rmCommand
}
