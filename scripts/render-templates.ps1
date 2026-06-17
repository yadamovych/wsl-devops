#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoRoot 'config\kit.config.ps1')

$SecretsPath = Join-Path $RepoRoot 'config\secrets.local.ps1'
if (-not (Test-Path $SecretsPath)) {
    throw "Missing config\secrets.local.ps1 — copy from secrets.local.ps1.example and edit."
}
. $SecretsPath

if ($LinuxPassword -eq 'CHANGE_ME') {
    throw "Edit config\secrets.local.ps1 — LinuxPassword is still CHANGE_ME."
}

$RenderDir = Join-Path $RepoRoot '.cloud-init-rendered'
New-Item -ItemType Directory -Force -Path $RenderDir | Out-Null

$Replacements = @{
    '{{TIMEZONE}}'        = $Timezone
    '{{LOCALE}}'          = $Locale
    '{{LINUX_USERNAME}}'  = $LinuxUsername
    '{{LINUX_PASSWORD}}'  = $LinuxPassword
    '{{GIT_USER_NAME}}'   = $GitUserName
    '{{GIT_USER_EMAIL}}'  = $GitUserEmail
    '{{SSH_KEY_COMMENT}}' = $SshKeyComment
    '{{WSL_MEMORY}}'      = $WslMemory
    '{{WSL_PROCESSORS}}'  = [string]$WslProcessors
    '{{WSL_SWAP}}'          = $WslSwap
}

function Expand-Template {
    param([string]$Path, [string]$OutPath)
    $content = Get-Content -Raw -Path $Path
    foreach ($key in $Replacements.Keys) {
        $content = $content.Replace($key, $Replacements[$key])
    }
    if (-not $content.StartsWith('#cloud-config') -and $Path -like '*user-data*') {
        throw "Rendered cloud-init must start with #cloud-config"
    }
    Set-Content -Path $OutPath -Value $content -Encoding utf8NoBOM
}

$CloudInitTemplate = Join-Path $RepoRoot 'cloud-init\Ubuntu-DevOps.user-data.template'
$CloudInitOut = Join-Path $RenderDir "$DistroName.user-data"
Expand-Template -Path $CloudInitTemplate -OutPath $CloudInitOut

$WslConfigTemplate = Join-Path $RepoRoot 'config\wsl.config.template'
$WslConfigOut = Join-Path $RenderDir '.wslconfig'
Expand-Template -Path $WslConfigTemplate -OutPath $WslConfigOut

Write-Host "Rendered cloud-init: $CloudInitOut"
Write-Host "Rendered wslconfig:   $WslConfigOut"
