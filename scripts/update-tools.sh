#!/usr/bin/env bash
# Refresh kit-pinned CLI tools inside an existing WSL distro.
# Versions are read from .cloud-init-rendered/tool-versions.env (from config/tool-versions.ps1).
#
# Windows (recommended):
#   .\scripts\update-tools.ps1
#
# Inside WSL (after render-templates.ps1):
#   sudo bash /path/to/wsl-devops/scripts/update-tools.sh
#
# Keep install steps in sync with cloud-init/Ubuntu-DevOps.user-data.template.

set -euo pipefail

if [[ -n "${KIT_REPO_ROOT:-}" ]]; then
  REPO_ROOT="$KIT_REPO_ROOT"
elif [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
  echo 'Cannot determine repo root (set KIT_REPO_ROOT or run as a script file).' >&2
  exit 1
fi
ENV_FILE="${KIT_TOOL_VERSIONS:-$REPO_ROOT/.cloud-init-rendered/tool-versions.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE - run scripts/render-templates.ps1 (or .\scripts\update-tools.ps1) first." >&2
  exit 1
fi

# shellcheck source=/dev/null
source <(sed 's/\r$//' "$ENV_FILE")

if [[ $EUID -ne 0 ]]; then
  echo "Re-run with sudo." >&2
  exit 1
fi

export PATH="/snap/bin:$PATH"
export DEBIAN_FRONTEND=noninteractive

echo "=== Refreshing kit tools from tool-versions.ps1 ==="
echo "  aws-cli   -> ${AWS_CLI_VERSION}"
echo "  kubectl   -> channel ${KUBECTL_CHANNEL}/stable"
echo "  opentofu  -> ${OPENTOFU_VERSION}"
echo "  helm      -> ${HELM_VERSION}"
echo "  glab      -> ${GLAB_VERSION}"
echo "  asdf      -> ${ASDF_VERSION}"
echo "  gitlabber -> ${GITLABBER_VERSION}"
echo "  oh-my-zsh -> pin ${OH_MY_ZSH_PIN} @ ${OH_MY_ZSH_COMMIT:0:12}"
echo ""

# -- Snap tools (channel-pinned) ---------------------------------------------
_kubectl_channel="${KUBECTL_CHANNEL}/stable"
if snap list kubectl &>/dev/null; then
  echo ">> snap refresh kubectl --channel=${_kubectl_channel}"
  snap refresh kubectl --classic --channel="${_kubectl_channel}"
else
  echo ">> snap install kubectl --channel=${_kubectl_channel}"
  snap install kubectl --classic --channel="${_kubectl_channel}"
fi

# -- Binary tools (version-pinned) ---------------------------------------------
AWS_VER="${AWS_CLI_VERSION}"
echo ">> aws-cli ${AWS_VER}"
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_VER}.zip" -o /tmp/awscliv2.zip
unzip -q -o /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/awscliv2.zip /tmp/aws

OTF_VER="${OPENTOFU_VERSION}"
echo ">> opentofu ${OTF_VER}"
curl -fsSL "https://github.com/opentofu/opentofu/releases/download/v${OTF_VER}/tofu_${OTF_VER}_linux_amd64.tar.gz" \
  -o /tmp/tofu.tar.gz
tar -xzf /tmp/tofu.tar.gz -C /usr/local/bin tofu
chmod +x /usr/local/bin/tofu
rm /tmp/tofu.tar.gz

HELM_VER="${HELM_VERSION}"
echo ">> helm ${HELM_VER}"
curl -fsSL "https://get.helm.sh/helm-v${HELM_VER}-linux-amd64.tar.gz" -o /tmp/helm.tar.gz
tar -xzf /tmp/helm.tar.gz -C /tmp linux-amd64/helm
install -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm
rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

GLAB_VER="${GLAB_VERSION}"
echo ">> glab ${GLAB_VER}"
curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VER}/downloads/glab_${GLAB_VER}_linux_amd64.tar.gz" \
  -o /tmp/glab.tar.gz
tar -xzf /tmp/glab.tar.gz -C /tmp
install -m 0755 /tmp/bin/glab /usr/local/bin/glab
rm -rf /tmp/glab.tar.gz /tmp/bin

ASDF_VER="${ASDF_VERSION}"
echo ">> asdf ${ASDF_VER}"
curl -fsSL "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VER}/asdf-v${ASDF_VER}-linux-amd64.tar.gz" \
  -o /tmp/asdf.tar.gz
tar -xzf /tmp/asdf.tar.gz -C /usr/local/bin asdf
chmod +x /usr/local/bin/asdf
rm /tmp/asdf.tar.gz

# -- gitlabber (user pipx) -----------------------------------------------------
echo ">> gitlabber ${GITLABBER_VERSION}"
sudo -u "${LINUX_USERNAME}" env \
  HOME="/home/${LINUX_USERNAME}" \
  PATH="/home/${LINUX_USERNAME}/.local/bin:/snap/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  PIP_NO_INPUT=1 NO_COLOR=1 FORCE_COLOR=0 \
  pipx install --force "gitlabber==${GITLABBER_VERSION}"

# -- oh-my-zsh (pinned commit tarball) ---------------------------------------
echo ">> oh-my-zsh pin ${OH_MY_ZSH_PIN} @ ${OH_MY_ZSH_COMMIT:0:12}"
sed 's/\r$//' "${REPO_ROOT}/scripts/install-oh-my-zsh.sh" | \
  OH_MY_ZSH_PIN="${OH_MY_ZSH_PIN}" OH_MY_ZSH_COMMIT="${OH_MY_ZSH_COMMIT}" \
  KIT_REPO_ROOT="${REPO_ROOT}" KIT_ZSH_CUSTOM_DIR="${REPO_ROOT}/scripts/kit-oh-my-zsh-custom" \
  GITLABBER_CLONE_METHOD="${GITLABBER_CLONE_METHOD:-http}" \
  bash -s -- "${LINUX_USERNAME}"

# -- VS Code / Cursor CLI wrappers ---------------------------------------------
sed 's/\r$//' "${REPO_ROOT}/scripts/install-wsl-editors.sh" | bash -s -- "${LINUX_USERNAME}"

# -- Windows browser helper (AWS SSO login, etc.) ------------------------------
sed 's/\r$//' "${REPO_ROOT}/scripts/install-wsl-browser.sh" | bash -s -- "${LINUX_USERNAME}"

echo ""
echo "=== Installed versions ==="
aws --version 2>&1 | head -1 || true
kubectl version --client 2>/dev/null | head -1 || true
tofu version 2>/dev/null | head -1 || true
helm version --short 2>/dev/null | head -1 || true
glab --version 2>/dev/null | head -1 || true
asdf version 2>/dev/null | head -1 || true
sudo -u "${LINUX_USERNAME}" gitlabber --version 2>/dev/null | head -1 || true
echo ""
echo "=== Done. Run scripts/verify.ps1 for a full check. ==="
