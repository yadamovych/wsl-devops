#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoRoot 'config\kit.config.ps1')

function Test-CommandExists {
    param([string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Host "=== WSL DevOps Kit v$KitVersion ===" -ForegroundColor Cyan

if (-not (Test-CommandExists 'wsl')) {
    throw 'WSL not found. Run: wsl --install, then reboot.'
}

$wslVersion = wsl --version 2>&1
Write-Host $wslVersion

& (Join-Path $PSScriptRoot 'deploy-cloud-init.ps1')
& (Join-Path $PSScriptRoot 'deploy-wslconfig.ps1')

if (-not (Test-Path $WslImagePath)) {
    Write-Host "Downloading WSL image to $WslImagePath ..."
    New-Item -ItemType Directory -Force -Path (Split-Path $WslImagePath) | Out-Null
    Invoke-WebRequest -Uri $WslImageUrl -OutFile $WslImagePath -UseBasicParsing
}

Write-Host "Verifying SHA256 ..."
$shaFile = Join-Path $env:TEMP 'ubuntu-wsl-SHA256SUMS'
Invoke-WebRequest -Uri $WslSha256Url -OutFile $shaFile -UseBasicParsing
$expectedLine = Get-Content $shaFile | Where-Object { $_ -match 'ubuntu-26.04-wsl-amd64\.wsl' }
if ($expectedLine) {
    $expectedHash = ($expectedLine -split '\s+', 2)[0]
    $actualHash = (Get-FileHash $WslImagePath -Algorithm SHA256).Hash.ToLower()
    if ($actualHash -ne $expectedHash.ToLower()) {
        throw "SHA256 mismatch for $WslImagePath"
    }
    Write-Host "SHA256 OK"
} else {
    Write-Warning "Could not find hash line in SHA256SUMS — skipping verification"
}

$existing = wsl --list --quiet 2>$null
if ($existing -contains $DistroName) {
    Write-Host "Distro '$DistroName' already exists. Run scripts\uninstall.ps1 first for a clean install." -ForegroundColor Yellow
    exit 1
}

Write-Host ('Installing {0} from .wsl bundle with --no-launch ...' -f $DistroName)
wsl --install --from-file $WslImagePath --name $DistroName --no-launch

wsl --set-default $DistroName
wsl --set-version $DistroName 2 2>$null

Write-Host 'First launch — cloud-init provisioning, about 5-15 min ...'
wsl -d $DistroName -e bash -lc "echo 'Provisioning started'; exit 0"

Write-Host 'Applying .wslconfig — shutdown and restart ...'
wsl --shutdown
Start-Sleep -Seconds 8
wsl -d $DistroName -e bash -lc "echo 'WSL restarted'; exit 0"

& (Join-Path $PSScriptRoot 'verify.ps1')

Write-Host ""
Write-Host "Install complete. Complete manual steps:" -ForegroundColor Green
Write-Host "  checklists\repeat-install.md"
