#Requires -Version 5.1
Set-StrictMode -Version Latest

function Normalize-VersionString {
    <#
    .SYNOPSIS
    Strips a leading 'v' and returns a string safe for [version] parsing.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Version)

    ($Version -replace '^v', '').Trim()
}

function Compare-PinnedVersion {
    <#
    .SYNOPSIS
    Returns -1 if pinned < latest, 0 if equal, 1 if pinned > latest, $null if not comparable.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Pinned,
        [Parameter(Mandatory)][string]$Latest
    )

    $p = Normalize-VersionString -Version $Pinned
    $l = Normalize-VersionString -Version $Latest
    try {
        $pv = [version]$p
        $lv = [version]$l
        return [Math]::Sign($pv.CompareTo($lv))
    }
    catch {
        if ($p -eq $l) { return 0 }
        return $null
    }
}

function Get-GitHubLatestReleaseTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Owner,
        [Parameter(Mandatory)][string]$Repo
    )

    $uri = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
    $headers = @{
        'User-Agent' = 'wsl-devops-kit'
        Accept       = 'application/vnd.github+json'
    }
    $release = Invoke-RestMethod -Uri $uri -Headers $headers
    return ($release.tag_name -replace '^v', '')
}

function Get-GitLabLatestReleaseTag {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectPath)

    $encoded = [uri]::EscapeDataString($ProjectPath)
    $uri = "https://gitlab.com/api/v4/projects/$encoded/releases?per_page=1"
    $headers = @{ 'User-Agent' = 'wsl-devops-kit' }
    $releases = Invoke-RestMethod -Uri $uri -Headers $headers
    if (-not $releases -or $releases.Count -eq 0) {
        throw "No GitLab releases found for $ProjectPath"
    }
    return ($releases[0].tag_name -replace '^v', '')
}

function Get-PypiLatestVersion {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Package)

    $uri = "https://pypi.org/pypi/$Package/json"
    $headers = @{ 'User-Agent' = 'wsl-devops-kit' }
    $data = Invoke-RestMethod -Uri $uri -Headers $headers
    return [string]$data.info.version
}

function Get-GitHubBranchHeadSha {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Owner,
        [Parameter(Mandatory)][string]$Repo,
        [string]$Branch = 'master'
    )

    $uri = "https://api.github.com/repos/$Owner/$Repo/commits/$Branch"
    $headers = @{
        'User-Agent' = 'wsl-devops-kit'
        Accept       = 'application/vnd.github+json'
    }
    $commit = Invoke-RestMethod -Uri $uri -Headers $headers
    return [string]$commit.sha
}

function Get-SnapInfo {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SnapName)

    $uri = "https://api.snapcraft.io/v2/snaps/info/$SnapName"
    $headers = @{ 'Snap-Device-Series' = '16'; 'User-Agent' = 'wsl-devops-kit' }
    return Invoke-RestMethod -Uri $uri -Headers $headers
}

function Get-SnapStableVersion {
    <#
    .SYNOPSIS
    Latest version on a snap track/risk for linux amd64 (e.g. track 1.32, risk stable).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SnapName,
        [Parameter(Mandatory)][string]$Track,
        [string]$Risk = 'stable'
    )

    $info = Get-SnapInfo -SnapName $SnapName
    foreach ($entry in $info.'channel-map') {
        $ch = $entry.channel
        if ($ch.architecture -eq 'amd64' -and $ch.track -eq $Track -and $ch.risk -eq $Risk) {
            return [string]$entry.version
        }
    }
    throw "Snap channel not found: $SnapName $Track/$Risk (amd64)"
}

function Get-SnapLatestStableTrack {
    <#
    .SYNOPSIS
    Highest numeric stable track on a snap (excludes 'latest'), e.g. 1.35 for kubectl.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SnapName)

    $info = Get-SnapInfo -SnapName $SnapName
    $tracks = @()
    foreach ($entry in $info.'channel-map') {
        $ch = $entry.channel
        if ($ch.architecture -ne 'amd64' -or $ch.risk -ne 'stable') { continue }
        if ($ch.track -eq 'latest') { continue }
        try {
            $tracks += [pscustomobject]@{
                Track   = $ch.track
                Version = [string]$entry.version
                SortKey = [version](Normalize-VersionString -Version $ch.track)
            }
        }
        catch { }
    }
    if ($tracks.Count -eq 0) {
        throw "No versioned stable tracks found for snap $SnapName"
    }
    return ($tracks | Sort-Object -Property SortKey -Descending | Select-Object -First 1)
}

Export-ModuleMember -Function @(
    'Normalize-VersionString'
    'Compare-PinnedVersion'
    'Get-GitHubLatestReleaseTag'
    'Get-GitHubBranchHeadSha'
    'Get-GitLabLatestReleaseTag'
    'Get-PypiLatestVersion'
    'Get-SnapInfo'
    'Get-SnapStableVersion'
    'Get-SnapLatestStableTrack'
)
