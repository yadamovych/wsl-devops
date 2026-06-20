#Requires -Version 5.1
<#
.SYNOPSIS
Rebuild the Graphify knowledge graph with Groq-safe token settings.

.DESCRIPTION
Code changes: use -CodeOnly (AST-only, no API cost).
Doc changes or first build: uses Groq with small chunks to stay under the free-tier
12,000 tokens/minute limit (default --token-budget 3000, --max-concurrency 1).

Requires GROQ_API_KEY in the user environment and graphify on PATH or Python 3.12+.

.EXAMPLE
.\scripts\rebuild-graph.ps1 -CodeOnly

.EXAMPLE
.\scripts\rebuild-graph.ps1 -Update
#>
[CmdletBinding()]
param(
    [switch]$CodeOnly,
    [switch]$Update,
    [ValidateRange(500, 60000)]
    [int]$TokenBudget = 3000,
    [ValidateRange(1, 16)]
    [int]$MaxConcurrency = 1,
    [string]$Backend = 'groq',
    [switch]$NoViz
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Allow .graphify/providers.json in this repo (Groq backend config).
$env:GRAPHIFY_ALLOW_LOCAL_PROVIDERS = '1'

$RepoRoot = Split-Path -Parent $PSScriptRoot

function Get-GraphifyExe {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\Scripts\graphify.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python313\Scripts\graphify.exe')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    if (Get-Command graphify -ErrorAction SilentlyContinue) {
        return 'graphify'
    }

    throw 'graphify not found. Install: py -3.12 -m pip install graphifyy openai'
}

function Invoke-Graphify {
    param(
        [Parameter(Mandatory)]
        [string[]]$GraphifyArgs
    )

    $graphify = Get-GraphifyExe
    if ($graphify -eq 'graphify') {
        & graphify @GraphifyArgs
    }
    else {
        & $graphify @GraphifyArgs
    }

    if ($LASTEXITCODE -ne 0) {
        throw "graphify failed (exit $LASTEXITCODE): graphify $($GraphifyArgs -join ' ')"
    }
}

Push-Location $RepoRoot
try {
    if ($CodeOnly) {
        Write-Host '[rebuild-graph] AST-only update (no LLM tokens).' -ForegroundColor Cyan
        Invoke-Graphify @('.', 'update')
        Invoke-Graphify @('cluster-only', '.', '--no-label')
        if (-not $NoViz) {
            Invoke-Graphify @('export', 'callflow-html')
        }
        return
    }

    if (-not $env:GROQ_API_KEY) {
        $env:GROQ_API_KEY = [Environment]::GetEnvironmentVariable('GROQ_API_KEY', 'User')
    }
    if (-not $env:GROQ_API_KEY) {
        throw 'GROQ_API_KEY is not set. Create one at https://console.groq.com/keys and save it to your user environment.'
    }

    $extractArgs = @(
        'extract', '.',
        '--backend', $Backend,
        '--token-budget', [string]$TokenBudget,
        '--max-concurrency', [string]$MaxConcurrency
    )
    if ($Update) {
        Write-Host '[rebuild-graph] Incremental semantic extract (cached files skipped).' -ForegroundColor Cyan
    }
    else {
        Write-Host "[rebuild-graph] Full extract via $Backend (token-budget=$TokenBudget, max-concurrency=$MaxConcurrency)." -ForegroundColor Cyan
    }

    Invoke-Graphify $extractArgs

    $clusterArgs = @(
        'cluster-only', '.',
        '--backend', $Backend,
        '--token-budget', [string]$TokenBudget,
        '--no-label'
    )
    Invoke-Graphify $clusterArgs

    if (-not $NoViz) {
        Invoke-Graphify @('export', 'callflow-html')
    }

    Write-Host '[rebuild-graph] Done. Open graphify-out/graph.html or graphify-out/GRAPH_REPORT.md' -ForegroundColor Green
}
finally {
    Pop-Location
}
