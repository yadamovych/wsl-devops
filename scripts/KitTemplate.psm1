#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Renders a kit template by substituting {{PLACEHOLDER}} tokens.
.DESCRIPTION
    Reads a template file, replaces every key found in $Replacements with its
    value, enforces the #cloud-config header for cloud-init user-data files, and
    writes the result as UTF-8 without a BOM (cloud-init rejects a BOM).
    This logic is platform-agnostic so it can be exercised/tested off Windows.
#>
function Expand-KitTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$OutPath,
        [Parameter(Mandatory)][hashtable]$Replacements
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw ('Template not found: {0}' -f $Path)
    }

    $content = Get-Content -Raw -Path $Path
    foreach ($key in $Replacements.Keys) {
        $content = $content.Replace($key, [string]$Replacements[$key])
    }

    if (($Path -like '*user-data*') -and (-not $content.StartsWith('#cloud-config'))) {
        throw 'Rendered cloud-init must start with #cloud-config'
    }

    # utf8NoBOM requires PS 6+; use .NET directly for PS 5.1 compatibility.
    [System.IO.File]::WriteAllText($OutPath, $content, [System.Text.UTF8Encoding]::new($false))
}

Export-ModuleMember -Function Expand-KitTemplate
