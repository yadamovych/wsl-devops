#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoRoot 'config\kit.config.ps1')

& (Join-Path $PSScriptRoot 'render-templates.ps1')

$Rendered = Join-Path $RepoRoot ".cloud-init-rendered\$DistroName.user-data"
$DestDir = Join-Path $env:USERPROFILE '.cloud-init'
$DestFile = Join-Path $DestDir "$DistroName.user-data"

New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
Copy-Item -Force $Rendered $DestFile
Write-Host "Deployed cloud-init to $DestFile"
