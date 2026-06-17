#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoRoot 'config\kit.config.ps1')

$distros = wsl --list --quiet 2>$null
if ($distros -notcontains $DistroName) {
    Write-Warning ('Distro {0} is not installed yet.' -f $DistroName)
    exit 1
}

Write-Host ('=== Verification: {0} ===' -f $DistroName) -ForegroundColor Cyan

$checks = @(
    'whoami'
    'cloud-init status'
    'systemctl is-system-running'
    'aws --version'
    'tofu version'
    'kubectl version --client 2>/dev/null || true'
    'helm version --short 2>/dev/null || true'
    'asdf version'
    'glab --version'
    'zsh --version'
    'git --version'
    'jq --version'
)

foreach ($cmd in $checks) {
    Write-Host ('>> {0}' -f $cmd) -ForegroundColor DarkGray
    wsl -d $DistroName bash -lc $cmd
}

Write-Host ''
Write-Host 'Manual checks after AWS SSO + Docker Desktop setup:' -ForegroundColor Yellow
Write-Host '  aws sts get-caller-identity'
Write-Host '  docker run --rm hello-world'
Write-Host '  cat ~/.ssh/id_ed25519.pub  # add to GitHub/GitLab'
