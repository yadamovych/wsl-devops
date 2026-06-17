#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoRoot 'config\kit.config.ps1')

Write-Host "Unregistering WSL distro: $DistroName"
wsl --terminate $DistroName 2>$null
wsl --unregister $DistroName
Write-Host "Done. Run scripts\install.ps1 to reprovision."
