#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoRoot 'config\kit.config.ps1')

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    throw 'WSL not found. Run: wsl --install, then reboot.'
}

$distros = wsl --list --quiet 2>$null
if ($distros -notcontains $DistroName) {
    throw "Distro '$DistroName' is not installed. Run scripts\install.ps1 first."
}

& (Join-Path $PSScriptRoot 'render-templates.ps1')

$envFile = Join-Path $RepoRoot '.cloud-init-rendered\tool-versions.env'
Write-Host 'Pinned versions:' -ForegroundColor DarkGray
Get-Content $envFile | Where-Object { $_ -match "^(ASDF|AWS_CLI|GLAB|GITLABBER|HELM|KUBECTL|OPENTOFU)_" } | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
Write-Host ''

function ConvertTo-WslPath {
    param([Parameter(Mandatory)][string]$WindowsPath)
    $resolved = (Resolve-Path -LiteralPath $WindowsPath).Path
    if ($resolved -notmatch '^([A-Za-z]):\\(.*)$') {
        throw "Cannot convert path to WSL: $WindowsPath"
    }
    $drive = $Matches[1].ToLower()
    $rest = $Matches[2] -replace '\\', '/'
    return "/mnt/$drive/$rest"
}

$repoWsl = ConvertTo-WslPath -WindowsPath $RepoRoot
$scriptWsl = "$repoWsl/scripts/update-tools.sh"

Write-Host ("=== Updating kit tools in {0} ===" -f $DistroName) -ForegroundColor Cyan
# Single-quoted segments keep bash $vars (e.g. sed's $ anchor) out of PowerShell's reach.
$bashCmd = 'sed ''s/\r$//'' ''' + $scriptWsl + ''' | sudo env KIT_REPO_ROOT=''' + $repoWsl + ''' bash'
wsl.exe -d $DistroName bash -lc $bashCmd
