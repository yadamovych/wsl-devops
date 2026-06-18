#Requires -Version 5.1
<#
.SYNOPSIS
Compare config/tool-versions.ps1 pins against latest upstream releases.

.EXAMPLE
.\scripts\check-tool-updates.ps1

.EXAMPLE
.\scripts\check-tool-updates.ps1 -FailIfUpdates
#>
[CmdletBinding()]
param(
    [switch]$FailIfUpdates
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoRoot 'config\tool-versions.ps1')
Import-Module (Join-Path $PSScriptRoot 'KitToolVersions.psm1') -Force

$results = [System.Collections.Generic.List[object]]::new()
$updatesAvailable = $false

function Add-ToolCheck {
    param(
        [string]$Tool,
        [string]$Pinned,
        [string]$Upstream,
        [string]$Notes = ''
    )

    $cmp = Compare-PinnedVersion -Pinned $Pinned -Latest $Upstream
    $status = if ($null -eq $cmp) {
        if ($Pinned -eq $Upstream) { 'current' } else { 'check manually' }
    }
    elseif ($cmp -lt 0) { 'update available' }
    elseif ($cmp -eq 0) { 'current' }
    else { 'pinned ahead' }

    if ($status -eq 'update available') { $script:updatesAvailable = $true }

    $script:results.Add([pscustomobject]@{
            Tool     = $Tool
            Pinned   = $Pinned
            Upstream = $Upstream
            Status   = $status
            Notes    = $Notes
        })
}

function Add-ChannelCheck {
    param(
        [string]$Tool,
        [string]$PinnedTrack,
        [string]$LatestTrack,
        [string]$LatestTrackVersion,
        [string]$PinnedTrackVersion = ''
    )

    $trackCmp = Compare-PinnedVersion -Pinned $PinnedTrack -Latest $LatestTrack
    $notes = "pinned track $PinnedTrack/stable"
    if ($PinnedTrackVersion) {
        $notes += " -> $PinnedTrackVersion"
    }

    if ($null -ne $trackCmp -and $trackCmp -lt 0) {
        $script:updatesAvailable = $true
        $status = 'newer track available'
        $upstream = "$LatestTrack ($LatestTrackVersion)"
        $notes += "; latest track $LatestTrack/stable"
    }
    else {
        $status = 'current track'
        $upstream = if ($PinnedTrackVersion) { $PinnedTrackVersion } else { "$PinnedTrack/stable" }
        if ($LatestTrack -ne $PinnedTrack) {
            $notes += "; newest track $LatestTrack/stable -> $LatestTrackVersion"
        }
    }

    $script:results.Add([pscustomobject]@{
            Tool     = $Tool
            Pinned   = $PinnedTrack
            Upstream = $upstream
            Status   = $status
            Notes    = $Notes
        })
}

Write-Host '=== Upstream version check (config/tool-versions.ps1) ===' -ForegroundColor Cyan
Write-Host 'Querying release APIs ...' -ForegroundColor DarkGray
Write-Host ''

try {
    $asdfLatest = Get-GitHubLatestReleaseTag -Owner 'asdf-vm' -Repo 'asdf'
    Add-ToolCheck -Tool 'asdf' -Pinned $AsdfVersion -Upstream $asdfLatest
}
catch {
    $results.Add([pscustomobject]@{ Tool = 'asdf'; Pinned = $AsdfVersion; Upstream = '?'; Status = 'error'; Notes = $_.Exception.Message })
}

try {
    $glabLatest = Get-GitLabLatestReleaseTag -ProjectPath 'gitlab-org/cli'
    Add-ToolCheck -Tool 'glab' -Pinned $GlabVersion -Upstream $glabLatest
}
catch {
    $results.Add([pscustomobject]@{ Tool = 'glab'; Pinned = $GlabVersion; Upstream = '?'; Status = 'error'; Notes = $_.Exception.Message })
}

try {
    $gitlabberLatest = Get-PypiLatestVersion -Package 'gitlabber'
    Add-ToolCheck -Tool 'gitlabber' -Pinned $GitlabberVersion -Upstream $gitlabberLatest
}
catch {
    $results.Add([pscustomobject]@{ Tool = 'gitlabber'; Pinned = $GitlabberVersion; Upstream = '?'; Status = 'error'; Notes = $_.Exception.Message })
}

try {
    $helmLatest = Get-GitHubLatestReleaseTag -Owner 'helm' -Repo 'helm'
    Add-ToolCheck -Tool 'helm' -Pinned $HelmVersion -Upstream $helmLatest
}
catch {
    $results.Add([pscustomobject]@{ Tool = 'helm'; Pinned = $HelmVersion; Upstream = '?'; Status = 'error'; Notes = $_.Exception.Message })
}

try {
    $tofuLatest = Get-GitHubLatestReleaseTag -Owner 'opentofu' -Repo 'opentofu'
    Add-ToolCheck -Tool 'opentofu' -Pinned $OpenTofuVersion -Upstream $tofuLatest
}
catch {
    $results.Add([pscustomobject]@{ Tool = 'opentofu'; Pinned = $OpenTofuVersion; Upstream = '?'; Status = 'error'; Notes = $_.Exception.Message })
}

try {
    $kubectlPinnedVer = Get-SnapStableVersion -SnapName 'kubectl' -Track $KubectlChannel
    $kubectlLatest = Get-SnapLatestStableTrack -SnapName 'kubectl'
    Add-ChannelCheck -Tool 'kubectl' -PinnedTrack $KubectlChannel `
        -LatestTrack $kubectlLatest.Track -LatestTrackVersion $kubectlLatest.Version `
        -PinnedTrackVersion $kubectlPinnedVer
}
catch {
    $results.Add([pscustomobject]@{ Tool = 'kubectl'; Pinned = $KubectlChannel; Upstream = '?'; Status = 'error'; Notes = $_.Exception.Message })
}

try {
    $awsLatest = Get-GitHubLatestReleaseTag -Owner 'aws' -Repo 'aws-cli'
    Add-ToolCheck -Tool 'aws-cli' -Pinned $AwsCliVersion -Upstream $awsLatest
}
catch {
    $results.Add([pscustomobject]@{ Tool = 'aws-cli'; Pinned = $AwsCliVersion; Upstream = '?'; Status = 'error'; Notes = $_.Exception.Message })
}

$results | Format-Table -AutoSize Tool, Pinned, Upstream, Status, Notes

$actionable = @($results | Where-Object { $_.Status -in @('update available', 'newer track available') })
if ($actionable.Count -gt 0) {
    Write-Host ''
    Write-Host 'To upgrade:' -ForegroundColor Yellow
    Write-Host '  1. Edit config\tool-versions.ps1'
    Write-Host '  2. .\scripts\update-tools.ps1'
}
else {
    Write-Host ''
    Write-Host 'All pinned versions match upstream (or use a current snap track).' -ForegroundColor Green
}

if ($FailIfUpdates -and $updatesAvailable) {
    exit 1
}
