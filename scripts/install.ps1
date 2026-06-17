#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoRoot 'config\kit.config.ps1')

function Test-CommandExists {
    param([string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Host ('=== WSL DevOps Kit v{0} ===' -f $KitVersion) -ForegroundColor Cyan

if (-not (Test-CommandExists 'wsl')) {
    throw 'WSL not found. Run: wsl --install, then reboot.'
}

$wslVersion = wsl --version 2>&1
Write-Host $wslVersion

& (Join-Path $PSScriptRoot 'deploy-cloud-init.ps1')
& (Join-Path $PSScriptRoot 'deploy-wslconfig.ps1')

if (-not (Test-Path $WslImagePath)) {
    Write-Host ('Downloading WSL image to {0} ...' -f $WslImagePath)
    New-Item -ItemType Directory -Force -Path (Split-Path $WslImagePath) | Out-Null
    Invoke-WebRequest -Uri $WslImageUrl -OutFile $WslImagePath -UseBasicParsing
}

Write-Host 'Verifying SHA256 ...'
$shaFile = Join-Path $env:TEMP 'ubuntu-wsl-SHA256SUMS'
Invoke-WebRequest -Uri $WslSha256Url -OutFile $shaFile -UseBasicParsing
$expectedLine = Get-Content $shaFile | Where-Object { $_ -match 'ubuntu-26\.04-wsl-amd64\.wsl' }
if ($expectedLine) {
    $expectedHash = ($expectedLine -split '\s+', 2)[0]
    $actualHash = (Get-FileHash $WslImagePath -Algorithm SHA256).Hash.ToLower()
    if ($actualHash -ne $expectedHash.ToLower()) {
        throw ('SHA256 mismatch for {0}' -f $WslImagePath)
    }
    Write-Host 'SHA256 OK'
} else {
    Write-Warning 'Could not find hash line in SHA256SUMS - skipping verification'
}

$existing = wsl --list --quiet 2>$null
if ($existing -contains $DistroName) {
    Write-Host ('Distro {0} already exists. Run scripts\uninstall.ps1 first.' -f $DistroName) -ForegroundColor Yellow
    exit 1
}

Write-Host ('Installing {0} from .wsl bundle with --no-launch ...' -f $DistroName)
wsl --install --from-file $WslImagePath --name $DistroName --no-launch

wsl --set-default $DistroName

# ── First boot: trigger cloud-init ───────────────────────────────────────────
# On first boot the default user is root because wsl.conf is written BY
# cloud-init, so the [user] default=devops block does not exist yet.
# The warning "Failed to start the systemd user session for 'root'" is
# expected and harmless: cloud-init runs as a system service, not a user
# service, and is unaffected by the failed root user session.
Write-Host 'First launch - triggering cloud-init ...'
Write-Host 'Note: "Failed to start the systemd user session for root" is expected on first boot.'

# ── WSL stderr emits a harmless warning on root first-boot ───────────────────
# PowerShell $ErrorActionPreference='Stop' converts any native-command stderr
# output into a terminating NativeCommandError, even with 2>$null.
# Relax to 'Continue' for all WSL calls in this section, then restore.
$savedEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'

# Short-lived command to trigger the first boot and start cloud-init.
wsl -d $DistroName -u root -- /bin/bash -c 'echo "WSL first boot OK"' 2>&1 | Out-Null

# ── Poll for cloud-init completion ────────────────────────────────────────────
# /var/lib/cloud/instance/boot-finished is the canonical marker that cloud-init
# creates after every stage (init, config, final) has completed successfully.
Write-Host 'Waiting for cloud-init provisioning (polling every 20s, up to 20 min) ...'
$deadline = (Get-Date).AddMinutes(20)
$done     = $false
while (-not $done -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 20
    # 2>&1 merges stderr into stdout so no NativeCommandError is generated.
    wsl -d $DistroName -u root -- test -f /var/lib/cloud/instance/boot-finished 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $done = $true
    } else {
        $status = (wsl -d $DistroName -u root -- cloud-init status 2>&1 |
                   Where-Object { $_ -notmatch 'systemd user session' }) -join ' '
        Write-Host ('[{0}] cloud-init: {1}' -f (Get-Date -Format 'HH:mm:ss'), $(if ($status.Trim()) { $status.Trim() } else { 'starting...' }))
        if ($status -match 'error') { break }
    }
}

$ErrorActionPreference = $savedEAP

if ($done) {
    Write-Host ''
    Write-Host '=== cloud-init done ===' -ForegroundColor Green
} else {
    Write-Warning 'cloud-init did not finish within 20 min.'
    Write-Warning 'Check manually: wsl -d Ubuntu-DevOps -- cloud-init status'
}

Write-Host 'Applying .wslconfig - shutdown and restart ...'
wsl --shutdown
Start-Sleep -Seconds 8
# Explicit default user avoids "Failed to start the systemd user session for root"
# when later WSL sessions launch as a normal user (wsl.conf alone is not always enough).
Write-Host ('Setting default user to {0} ...' -f $LinuxUsername)
wsl --manage $DistroName --set-default-user $LinuxUsername
$ErrorActionPreference = 'Continue'
wsl -d $DistroName -- bash -lc "echo 'WSL restarted OK'" 2>&1 | Out-Null
$ErrorActionPreference = 'Stop'

# ── Run bootstrap script ────────────────────────────────────────────────────────
# On WSL, cloud-init's runcmd is not reliably executed. Run the bootstrap
# script explicitly after restart. Use the default (non-root) user + sudo so
# WSL does not try to start a systemd user session for root.
Write-Host ''
Write-Host 'Running bootstrap script (5-10 min) ...'
$ErrorActionPreference = 'Continue'
wsl -d $DistroName -- sudo bash /opt/bootstrap-devops.sh 2>&1
$bootstrapExitCode = $LASTEXITCODE
$ErrorActionPreference = 'Stop'

if ($bootstrapExitCode -eq 0) {
    Write-Host 'Bootstrap completed successfully' -ForegroundColor Green
} else {
    Write-Host "Bootstrap failed with exit code $bootstrapExitCode" -ForegroundColor Red
    Write-Host 'Check the output above for errors. To retry:'
    Write-Host "  wsl -d $DistroName -- sudo bash /opt/bootstrap-devops.sh"
}

& (Join-Path $PSScriptRoot 'verify.ps1')

Write-Host ''
Write-Host 'Install complete. Complete manual steps:' -ForegroundColor Green
Write-Host '  checklists\repeat-install.md'
