param(
    [switch]$RemoveVolumes,
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
    'stop',
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

    if ($IncludeGoogleWorkspaceMcp) {
        $rmCommand += 'google-workspace-mcp'
    }

    if ($IncludeEstatMcp) {
        $rmCommand += 'estat-mcp'
    }

    & docker-compose @composeFiles @rmCommand
}
