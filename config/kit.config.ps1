# Shared settings — safe to commit. Edit to match your environment.
$KitVersion    = "1.1.0"
$DistroName    = "Ubuntu-DevOps"
$LinuxUsername = "devops"
$Timezone      = "Europe/Kyiv"
$Locale        = "en_US.UTF-8"
$WslImagePath  = "$env:USERPROFILE\Downloads\ubuntu-26.04-wsl-amd64.wsl"
$WslImageUrl   = "https://releases.ubuntu.com/26.04/ubuntu-26.04-wsl-amd64.wsl"
$WslSha256Url  = "https://releases.ubuntu.com/26.04/SHA256SUMS"
$WslMemory     = "8GB"
$WslProcessors = 4
$WslSwap       = "4GB"
# Optional: install the distro's VHDX to a custom folder/drive instead of the default
# location on C:. Leave empty ("") to use the default. Example: "D:\WSL\Ubuntu-DevOps".
# Requires WSL 2.4.4+ (passes 'wsl --install --location'); the folder is created if missing.
$WslInstallLocation = "D:\WSL\Ubuntu-DevOps"
# GitLab instance for gitlabber / glab (no trailing slash). Use gitlab.com or your self-hosted URL.
$GitLabUrl = "https://gitlab.com"
# gitlabber clone transport: "http" = HTTPS (+ token); "ssh" = git@ (no token in .git/config; needs SSH key in GitLab)
$GitlabberCloneMethod = "http"
