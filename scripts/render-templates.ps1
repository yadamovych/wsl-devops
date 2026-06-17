#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoRoot 'config\kit.config.ps1')
. (Join-Path $RepoRoot 'config\tool-versions.ps1')
Import-Module (Join-Path $PSScriptRoot 'KitTemplate.psm1') -Force

$SecretsPath = Join-Path $RepoRoot 'config\secrets.local.ps1'
if (-not (Test-Path $SecretsPath)) {
    throw 'Missing config\secrets.local.ps1 - copy from secrets.local.ps1.example and edit.'
}
. $SecretsPath

if ($LinuxPassword -eq 'CHANGE_ME') {
    throw 'Edit config\secrets.local.ps1 - LinuxPassword is still CHANGE_ME.'
}

$RenderDir = Join-Path $RepoRoot '.cloud-init-rendered'
New-Item -ItemType Directory -Force -Path $RenderDir | Out-Null

$Replacements = @{
    # --- identity / locale (from kit.config.ps1 + secrets.local.ps1) ---
    '{{TIMEZONE}}'          = $Timezone
    '{{LOCALE}}'            = $Locale
    '{{LINUX_USERNAME}}'    = $LinuxUsername
    '{{LINUX_PASSWORD}}'    = $LinuxPassword
    '{{GIT_USER_NAME}}'     = $GitUserName
    '{{GIT_USER_EMAIL}}'    = $GitUserEmail
    '{{SSH_KEY_COMMENT}}'   = $SshKeyComment
    # --- WSL VM settings (from kit.config.ps1) ---
    '{{WSL_MEMORY}}'        = $WslMemory
    '{{WSL_PROCESSORS}}'    = [string]$WslProcessors
    '{{WSL_SWAP}}'          = $WslSwap
    # --- tool versions (from tool-versions.ps1) ---
    '{{ASDF_VERSION}}'      = $AsdfVersion
    '{{GLAB_VERSION}}'              = $GlabVersion
    '{{GITLABBER_VERSION}}'         = $GitlabberVersion
    '{{GITLABBER_CLONE_METHOD}}'    = $GitlabberCloneMethod
    '{{KUBECTL_CHANNEL}}'           = $KubectlChannel
}

if ($GitlabberCloneMethod -notin @('http', 'ssh')) {
    throw 'config\kit.config.ps1: GitlabberCloneMethod must be "http" or "ssh".'
}

$CloudInitTemplate = Join-Path $RepoRoot 'cloud-init\Ubuntu-DevOps.user-data.template'
$CloudInitOut      = Join-Path $RenderDir ('{0}.user-data' -f $DistroName)
Expand-KitTemplate -Path $CloudInitTemplate -OutPath $CloudInitOut -Replacements $Replacements

$WslConfigTemplate = Join-Path $RepoRoot 'config\wsl.config.template'
$WslConfigOut      = Join-Path $RenderDir '.wslconfig'
Expand-KitTemplate -Path $WslConfigTemplate -OutPath $WslConfigOut -Replacements $Replacements

Write-Host ('Rendered cloud-init : {0}' -f $CloudInitOut)
Write-Host ('Rendered wslconfig  : {0}' -f $WslConfigOut)
