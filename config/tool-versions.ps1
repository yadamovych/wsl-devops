# Pinned tool versions — the only file to edit when upgrading a tool.
# Bump the version, commit, and reprovision.
#
# Release pages:
#   asdf  : https://github.com/asdf-vm/asdf/releases
#   glab  : https://gitlab.com/gitlab-org/cli/-/releases
#   helm  : https://github.com/helm/helm/releases     (fetched via install script, pinned below)
#   kubectl: set via channel in cloud-init template   (change KUBECTL_CHANNEL placeholder)

$AsdfVersion      = '0.19.0'
$GlabVersion      = '1.102.0'
$KubectlChannel   = 'v1.32'
