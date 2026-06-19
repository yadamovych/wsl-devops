#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoRoot 'config\kit.config.ps1')
. (Join-Path $RepoRoot 'config\tool-versions.ps1')
Import-Module (Join-Path $PSScriptRoot 'KitTemplate.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'KitSecrets.psm1') -Force

$SecretsPath = Join-Path $RepoRoot 'config\secrets.local.ps1'
$secretsStatus = Get-KitSecretsStatus -Path $SecretsPath
if (-not $secretsStatus.IsValid) {
    if (Test-KitInteractive) {
        # Offer to create/repair the secrets file instead of failing outright.
        Write-Host 'config/secrets.local.ps1 is missing or LinuxPassword is still "CHANGE_ME".' -ForegroundColor Yellow
        Request-KitSecrets -Path $SecretsPath -Force:$secretsStatus.Exists
    }
    elseif (-not $secretsStatus.Exists) {
        throw 'Missing config\secrets.local.ps1 - run scripts\new-secrets.ps1 (interactive) or copy config\secrets.local.ps1.example and edit.'
    }
    else {
        throw 'config\secrets.local.ps1 LinuxPassword is missing or still "CHANGE_ME" - run scripts\new-secrets.ps1 or edit it.'
    }
}
. $SecretsPath

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
    '{{ASDF_VERSION}}'              = $AsdfVersion
    '{{AWS_CLI_VERSION}}'           = $AwsCliVersion
    '{{GLAB_VERSION}}'              = $GlabVersion
    '{{GITLABBER_VERSION}}'         = $GitlabberVersion
    '{{GITLABBER_CLONE_METHOD}}'    = $GitlabberCloneMethod
    '{{GITLAB_URL}}'                = $GitLabUrl.TrimEnd('/')
    '{{HELM_VERSION}}'              = $HelmVersion
    '{{KUBECTL_CHANNEL}}'           = $KubectlChannel
    '{{OPENTOFU_VERSION}}'          = $OpenTofuVersion
    '{{OH_MY_ZSH_PIN}}'             = $OhMyZshPin
    '{{OH_MY_ZSH_COMMIT}}'          = $OhMyZshCommit
}

if ($GitLabUrl -notmatch '^https://') {
    throw 'config\kit.config.ps1: GitLabUrl must start with https:// (no trailing slash).'
}

if ($GitlabberCloneMethod -notin @('http', 'ssh')) {
    throw 'config\kit.config.ps1: GitlabberCloneMethod must be "http" or "ssh".'
}

if ($KubectlChannel -notmatch '^\d+\.\d+$') {
    throw @"
config\tool-versions.ps1: KubectlChannel must be a snap minor track (e.g. '1.35'), not a full version ('$KubectlChannel').
Patch versions are applied automatically on that track. Run .\scripts\check-tool-updates.ps1 to see the latest track.
"@
}

if ($OhMyZshCommit -notmatch '^[0-9a-fA-F]{40}$') {
    throw 'config\tool-versions.ps1: OhMyZshCommit must be a full 40-character git commit SHA (oh-my-zsh has no release tags).'
}

$editorScriptPath = Join-Path $RepoRoot 'scripts\install-wsl-editors.sh'
$editorYamlIndent = ' ' * 6
$editorScriptYaml = (
    (Get-Content -LiteralPath $editorScriptPath -Raw).TrimEnd().Split("`n") |
    ForEach-Object { $editorYamlIndent + $_ }
) -join "`n"
$Replacements['{{INSTALL_WSL_EDITORS_SCRIPT}}'] = $editorScriptYaml

$browserScriptPath = Join-Path $RepoRoot 'scripts\install-wsl-browser.sh'
$browserScriptYaml = (
    (Get-Content -LiteralPath $browserScriptPath -Raw).TrimEnd().Split("`n") |
    ForEach-Object { $editorYamlIndent + $_ }
) -join "`n"
$Replacements['{{INSTALL_WSL_BROWSER_SCRIPT}}'] = $browserScriptYaml

$omzScriptPath = Join-Path $RepoRoot 'scripts\install-oh-my-zsh.sh'
$omzScriptYaml = (
    (Get-Content -LiteralPath $omzScriptPath -Raw).TrimEnd().Split("`n") |
    ForEach-Object { $editorYamlIndent + $_ }
) -join "`n"
$Replacements['{{INSTALL_OH_MY_ZSH_SCRIPT}}'] = $omzScriptYaml

$customZshDir = Join-Path $RepoRoot 'scripts\kit-oh-my-zsh-custom'
$customYamlBlocks = [System.Collections.Generic.List[string]]::new()
Get-ChildItem -Path $customZshDir -Filter '*.zsh' | Sort-Object Name | ForEach-Object {
    $customYamlBlocks.Add("  - path: /opt/kit-oh-my-zsh-custom/$($_.Name)")
    $customYamlBlocks.Add("    permissions: '0644'")
    $customYamlBlocks.Add('    content: |')
    (Get-Content -LiteralPath $_.FullName -Raw).TrimEnd().Split("`n") | ForEach-Object {
        $customYamlBlocks.Add("      $_")
    }
}
$Replacements['{{KIT_ZSH_CUSTOM_WRITE_FILES}}'] = ($customYamlBlocks -join "`n")

$CloudInitTemplate = Join-Path $RepoRoot 'cloud-init\Ubuntu-DevOps.user-data.template'
$CloudInitOut      = Join-Path $RenderDir ('{0}.user-data' -f $DistroName)
Expand-KitTemplate -Path $CloudInitTemplate -OutPath $CloudInitOut -Replacements $Replacements

$WslConfigTemplate = Join-Path $RepoRoot 'config\wsl.config.template'
$WslConfigOut      = Join-Path $RenderDir '.wslconfig'
Expand-KitTemplate -Path $WslConfigTemplate -OutPath $WslConfigOut -Replacements $Replacements

$ToolVersionsEnv = Join-Path $RenderDir 'tool-versions.env'
$toolEnvLines = @(
    '# Generated by scripts/render-templates.ps1 - do not edit.'
    '# Sourced by scripts/update-tools.sh inside WSL.'
    ('LINUX_USERNAME=''{0}''' -f $LinuxUsername)
    ('GITLABBER_CLONE_METHOD=''{0}''' -f $GitlabberCloneMethod)
    ('GITLAB_URL=''{0}''' -f $GitLabUrl.TrimEnd('/'))
    ('ASDF_VERSION=''{0}''' -f $AsdfVersion)
    ('AWS_CLI_VERSION=''{0}''' -f $AwsCliVersion)
    ('GLAB_VERSION=''{0}''' -f $GlabVersion)
    ('GITLABBER_VERSION=''{0}''' -f $GitlabberVersion)
    ('HELM_VERSION=''{0}''' -f $HelmVersion)
    ('KUBECTL_CHANNEL=''{0}''' -f $KubectlChannel)
    ('OPENTOFU_VERSION=''{0}''' -f $OpenTofuVersion)
    ('OH_MY_ZSH_PIN=''{0}''' -f $OhMyZshPin)
    ('OH_MY_ZSH_COMMIT=''{0}''' -f $OhMyZshCommit)
) -join "`n"
[System.IO.File]::WriteAllText($ToolVersionsEnv, $toolEnvLines, [System.Text.UTF8Encoding]::new($false))

Write-Host ('Rendered cloud-init : {0}' -f $CloudInitOut)
Write-Host ('Rendered wslconfig  : {0}' -f $WslConfigOut)
Write-Host ('Rendered tool env   : {0}' -f $ToolVersionsEnv)
