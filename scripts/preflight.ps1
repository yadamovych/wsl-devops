#Requires -Version 5.1
[CmdletBinding()]
param([switch]$NonInteractive)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot 'KitSecrets.psm1') -Force

$SecretsPath = Join-Path $RepoRoot 'config\secrets.local.ps1'

# If secrets are missing/invalid and we are allowed to prompt, create them now.
$status = Get-KitSecretsStatus -Path $SecretsPath
if (-not $status.IsValid -and -not $NonInteractive -and (Test-KitInteractive)) {
    Write-Host 'config/secrets.local.ps1 is missing or incomplete.' -ForegroundColor Yellow
    Request-KitSecrets -Path $SecretsPath -Force:$status.Exists
    Write-Host ''
}

Write-Host '=== Prerequisite check ===' -ForegroundColor Cyan
$checks = Get-KitPrerequisite -SecretsPath $SecretsPath
foreach ($c in $checks) {
    if ($c.Ok)            { $label = '[ OK ]'; $color = 'Green' }
    elseif ($c.Required)  { $label = '[FAIL]'; $color = 'Red' }
    else                  { $label = '[WARN]'; $color = 'Yellow' }
    Write-Host ('{0} {1} - {2}' -f $label, $c.Name, $c.Detail) -ForegroundColor $color
}

$missing = @($checks | Where-Object { $_.Required -and -not $_.Ok })
if ($missing.Count -gt 0) {
    throw ('Missing required prerequisites: {0}' -f (($missing | ForEach-Object { $_.Name }) -join ', '))
}

Write-Host 'All required prerequisites satisfied.' -ForegroundColor Green
