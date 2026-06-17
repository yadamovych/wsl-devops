#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoRoot 'config\kit.config.ps1')

& (Join-Path $PSScriptRoot 'render-templates.ps1')

$Rendered = Join-Path $RepoRoot '.cloud-init-rendered\.wslconfig'
$Dest = Join-Path $env:USERPROFILE '.wslconfig'
Copy-Item -Force $Rendered $Dest
Write-Host "Deployed .wslconfig to $Dest"
