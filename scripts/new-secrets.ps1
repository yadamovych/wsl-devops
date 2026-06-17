#Requires -Version 5.1
[CmdletBinding()]
param([switch]$Force)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot 'KitSecrets.psm1') -Force

$SecretsPath = Join-Path $RepoRoot 'config\secrets.local.ps1'
Request-KitSecrets -Path $SecretsPath -Force:$Force
