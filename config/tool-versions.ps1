# Pinned tool versions — the only file to edit when upgrading a tool.
#
# In-place update (fast — keeps your distro, home dir, SSH keys):
#   1. Bump the version below and commit.
#   2. From Windows: .\scripts\update-tools.ps1
#
# Check upstream for newer releases:
#   .\scripts\check-tool-updates.ps1
#
# Full reprovision (slow — rebuilds the distro from scratch):
#   .\scripts\uninstall.ps1
#   .\scripts\install.ps1
#
# Release pages:
#   asdf     : https://github.com/asdf-vm/asdf/releases
#   aws-cli  : https://github.com/aws/aws-cli/releases
#   glab     : https://gitlab.com/gitlab-org/cli/-/releases
#   gitlabber: https://pypi.org/project/gitlabber/
#   helm     : https://github.com/helm/helm/releases
#   kubectl  : https://snapcraft.io/kubectl  (snap minor track, e.g. 1.35 → 1.35/stable)
#   opentofu : https://github.com/opentofu/opentofu/releases
#   oh-my-zsh: no upstream tags — pin $OhMyZshPin (kit label) + $OhMyZshCommit (immutable SHA).
#              https://github.com/ohmyzsh/ohmyzsh/commits/master

$AsdfVersion        = '0.19.0'
$OhMyZshPin         = '2026.06.15'
$OhMyZshCommit      = 'df34d2b8d575777465aed8ae9b7cd90d63fdcd6e'
$AwsCliVersion      = '2.35.7'
$GlabVersion        = '1.103.0'
$GitlabberVersion   = '2.1.1'
$HelmVersion        = '4.2.2'
$KubectlChannel     = '1.35'
$OpenTofuVersion    = '1.12.2'
