param(
    [ValidateSet('chatgpt', 'ollama')]
    [string]$ChatBackend = 'chatgpt',
    [switch]$SkipGoogleWorkspaceMcp,
    [switch]$SkipEstatMcp,
    [switch]$ForceEnv,
    [switch]$ForceWorkspaceFile,
    [switch]$StartStack,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path -Parent $repoRoot
$envExamplePath = Join-Path $repoRoot '.env.example'
$envPath = Join-Path $repoRoot '.env'

# workspaceRoot がドライブルート (例: C:\) の場合は repoRoot 直下に保存する
$workspaceRootResolved = $workspaceRoot.TrimEnd('\')
$isDriveRoot = $workspaceRootResolved -match '^[A-Za-z]:$'
if ($isDriveRoot) {
    $workspaceFilePath = Join-Path $repoRoot 'ark-injection-ai-system.code-workspace'
} else {
    $workspaceFilePath = Join-Path $workspaceRoot 'ark-injection-ai-system.code-workspace'
}

$allRepositories = @(
    [pscustomobject]@{ Name = 'amica'; RelativePath = 'amica'; Url = 'https://github.com/nftdrive01-maker/amica-nftdrive.git' },
    [pscustomobject]@{ Name = 'injection-tool'; RelativePath = 'injection-tool'; Url = 'https://github.com/nftdrive01-maker/ark-injection-tool.git' },
    [pscustomobject]@{ Name = 'mcp-server'; RelativePath = 'mcp-server'; Url = 'https://github.com/nftdrive01-maker/ark-mcp-server.git' },
    [pscustomobject]@{ Name = 'google-workspace-mcp'; RelativePath = 'google-workspace-mcp'; Url = 'https://github.com/nftdrive01-maker/google_workspace_mcp-nftdrive.git' },
    [pscustomobject]@{ Name = 'estat-mcp'; RelativePath = 'estat-mcp'; Url = 'https://github.com/nftdrive01-maker/estat-mcp-nftdrive.git' },
    [pscustomobject]@{ Name = 'piper'; RelativePath = 'piper'; Url = 'https://github.com/nftdrive01-maker/piper-nftdrive.git' },
    [pscustomobject]@{ Name = 'Style-Bert-VITS2'; RelativePath = 'sbv2/Style-Bert-VITS2'; Url = 'https://github.com/nftdrive01-maker/Style-Bert-VITS2-nftdrive.git' }
)

$skippedRepositoryNames = New-Object System.Collections.Generic.List[string]

if ($SkipGoogleWorkspaceMcp) {
    $skippedRepositoryNames.Add('google-workspace-mcp')
}

if ($SkipEstatMcp) {
    $skippedRepositoryNames.Add('estat-mcp')
}

$repositories = @($allRepositories | Where-Object { $skippedRepositoryNames -notcontains $_.Name })

function Invoke-ExternalCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )

    if ($DryRun) {
        Write-Host ('DRY RUN: ' + $FilePath + ' ' + ($Arguments -join ' '))
        return
    }

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ('Command failed: ' + $FilePath + ' ' + ($Arguments -join ' '))
    }
}

function Ensure-CommandAvailable {
    param([string]$CommandName)

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        throw ('Required command not found: ' + $CommandName)
    }
}

function Ensure-RepositoryPresent {
    param($Repository)

    $targetPath = Join-Path $workspaceRoot $Repository.RelativePath
    $targetParent = Split-Path -Parent $targetPath

    if (Test-Path (Join-Path $targetPath '.git')) {
        Write-Host ('Skip existing repository: ' + $Repository.Name)
        return
    }

    if (Test-Path $targetPath) {
        $childCount = (Get-ChildItem -Force -LiteralPath $targetPath | Measure-Object).Count
        if ($childCount -gt 0) {
            throw ('Target path exists and is not an empty git repository: ' + $targetPath)
        }
    } elseif (-not $DryRun) {
        if (-not (Test-Path -LiteralPath $targetParent)) {
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        }
    }

    Write-Host ('Cloning ' + $Repository.Name + ' into ' + $targetPath)
    Invoke-ExternalCommand -FilePath 'git' -Arguments @('clone', $Repository.Url, $targetPath)
}

function Set-EnvValue {
    param(
        [string]$Path,
        [string]$Key,
        [string]$Value
    )

    $lines = Get-Content -LiteralPath $Path -Encoding utf8
    $updated = $false

    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match ('^' + [regex]::Escape($Key) + '=')) {
            $lines[$index] = $Key + '=' + $Value
            $updated = $true
            break
        }
    }

    if (-not $updated) {
        $lines += ($Key + '=' + $Value)
    }

    if ($DryRun) {
        Write-Host ('DRY RUN: set ' + $Key + '=' + $Value + ' in ' + $Path)
        return
    }

    Set-Content -LiteralPath $Path -Value $lines -Encoding utf8
}

function Ensure-EnvFile {
    if ((Test-Path $envPath) -and -not $ForceEnv) {
        Write-Host 'Skip existing .env file. Use -ForceEnv to overwrite from .env.example.'
        return
    }

    if ($DryRun) {
        Write-Host ('DRY RUN: copy ' + $envExamplePath + ' -> ' + $envPath)
    } else {
        Copy-Item -LiteralPath $envExamplePath -Destination $envPath -Force
    }

    Set-EnvValue -Path $envPath -Key 'AMICA_CHATBOT_BACKEND' -Value $ChatBackend

    if ($ChatBackend -eq 'chatgpt') {
        Set-EnvValue -Path $envPath -Key 'AMICA_OPENAI_URL' -Value 'https://api.openai.com'
        Set-EnvValue -Path $envPath -Key 'AMICA_OPENAI_MODEL' -Value 'gpt-4o-mini'
    } else {
        Set-EnvValue -Path $envPath -Key 'AMICA_OLLAMA_URL' -Value 'http://host.docker.internal:11434'
        Set-EnvValue -Path $envPath -Key 'INJECTION_OLLAMA_URL' -Value 'http://host.docker.internal:11434'
        Set-EnvValue -Path $envPath -Key 'AMICA_OLLAMA_MODEL' -Value 'qwen2.5:7b'
    }
}

function Ensure-WorkspaceFile {
    if ((Test-Path $workspaceFilePath) -and -not $ForceWorkspaceFile) {
        Write-Host 'Skip existing .code-workspace file. Use -ForceWorkspaceFile to overwrite.'
        return
    }

    $folderEntries = @(
        @{ path = 'ark-injection-ai-system' }
    )

    foreach ($repository in $repositories) {
        $folderEntries += @{ path = $repository.RelativePath }
    }

    $workspaceConfig = [ordered]@{
        folders = $folderEntries
        settings = @{
            'files.exclude' = @{
                '**/.git' = $true
                '**/__pycache__' = $true
                '**/.pytest_cache' = $true
            }
        }
    }

    if ($DryRun) {
        Write-Host ('DRY RUN: write workspace file ' + $workspaceFilePath)
        return
    }

    $workspaceConfig | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $workspaceFilePath -Encoding utf8
}

Ensure-CommandAvailable -CommandName 'git'

Write-Host ('Workspace root: ' + $workspaceRoot)
Write-Host ('Current ark-injection-ai-system root: ' + $repoRoot)
Write-Host ('Selected chat backend: ' + $ChatBackend)

if ($skippedRepositoryNames.Count -gt 0) {
    Write-Host ('Skipped repositories: ' + ($skippedRepositoryNames -join ', '))
    Write-Host 'These repositories are omitted from clone targets and the generated .code-workspace file.'
}

foreach ($repository in $repositories) {
    Ensure-RepositoryPresent -Repository $repository
}

Ensure-EnvFile
Ensure-WorkspaceFile

Write-Host ''
Write-Host 'Workspace bootstrap completed.'
Write-Host ('- .env path: ' + $envPath)
Write-Host ('- workspace file: ' + $workspaceFilePath)
Write-Host '- Voice models, avatar assets, and character models are not downloaded by this script.'
Write-Host '- Review .env and set secrets before public use.'

if ($StartStack) {
    Write-Host ''
    Write-Host 'Starting development stack via scripts/dev-up-container-sbv2.ps1 -Build'
    Write-Host 'Optional MCP services remain stopped unless you start them explicitly.'

    if ($DryRun) {
        Write-Host ('DRY RUN: ' + (Join-Path $repoRoot 'scripts/dev-up-container-sbv2.ps1') + ' -Build')
    } else {
        & (Join-Path $repoRoot 'scripts/dev-up-container-sbv2.ps1') -Build
        if ($LASTEXITCODE -ne 0) {
            throw 'Failed to start development stack.'
        }
    }
}