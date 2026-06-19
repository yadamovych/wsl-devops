#!/usr/bin/env bash
# Install oh-my-zsh from a pinned GitHub tarball (immutable commit SHA).
# No upstream install.sh, no git fetch from master, no branch/tag refs.
#
# Usage:
#   sudo OH_MY_ZSH_COMMIT=<40-char-sha> bash install-oh-my-zsh.sh <linux-username>

set -euo pipefail

U="${1:-${LINUX_USERNAME:-}}"
OH_MY_ZSH_COMMIT="${OH_MY_ZSH_COMMIT:-${OH_MY_ZSH_REF:-}}"
OH_MY_ZSH_PIN="${OH_MY_ZSH_PIN:-}"
OMZ_TARBALL_BASE="${OH_MY_ZSH_TARBALL_BASE:-https://github.com/ohmyzsh/ohmyzsh/archive}"
GITLABBER_METHOD="${GITLABBER_CLONE_METHOD:-http}"
GITLAB_URL="${GITLAB_URL:-https://gitlab.com}"
GITLAB_URL="${GITLAB_URL%/}"
KIT_MARKER='# wsl-devops-kit zshrc'

if [[ -z "$U" ]]; then
  echo "Usage: $0 <linux-username>" >&2
  exit 1
fi

if [[ ! "$OH_MY_ZSH_COMMIT" =~ ^[0-9a-fA-F]{40}$ ]]; then
  echo "OH_MY_ZSH_COMMIT must be a full 40-character git commit SHA." >&2
  echo "oh-my-zsh publishes no release tags; do not pin branches like master." >&2
  exit 1
fi
OH_MY_ZSH_COMMIT="${OH_MY_ZSH_COMMIT,,}"

if ! command -v zsh >/dev/null 2>&1; then
  echo "zsh is not installed." >&2
  exit 1
fi

HOME_DIR="/home/$U"
OMZ_DIR="$HOME_DIR/.oh-my-zsh"
ZSHRC="$HOME_DIR/.zshrc"
PIN_FILE="$OMZ_DIR/.kit-pin"
TARBALL_URL="${OMZ_TARBALL_BASE}/${OH_MY_ZSH_COMMIT}.tar.gz"

_install_oh_my_zsh() {
  if [[ -f "$PIN_FILE" ]] && grep -q "^commit=${OH_MY_ZSH_COMMIT}$" "$PIN_FILE" 2>/dev/null; then
    echo ">> oh-my-zsh: already at commit ${OH_MY_ZSH_COMMIT:0:12}"
    _install_kit_zsh_custom
    return 0
  fi

  echo ">> oh-my-zsh: installing commit ${OH_MY_ZSH_COMMIT:0:12} from tarball"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  curl -fsSL "$TARBALL_URL" -o "${tmp_dir}/oh-my-zsh.tar.gz"
  tar -xzf "${tmp_dir}/oh-my-zsh.tar.gz" -C "$tmp_dir"
  extracted="${tmp_dir}/ohmyzsh-${OH_MY_ZSH_COMMIT}"
  if [[ ! -d "$extracted" ]]; then
    echo "Unexpected tarball layout (missing ohmyzsh-${OH_MY_ZSH_COMMIT})." >&2
    exit 1
  fi

  rm -rf "$OMZ_DIR"
  install -d -m 0755 -o "$U" -g "$U" "$(dirname "$OMZ_DIR")"
  mv "$extracted" "$OMZ_DIR"
  chown -R "$U:$U" "$OMZ_DIR"

  {
    echo "commit=${OH_MY_ZSH_COMMIT}"
    if [[ -n "$OH_MY_ZSH_PIN" ]]; then
      echo "pin=${OH_MY_ZSH_PIN}"
    fi
    echo "source=tarball"
    echo "installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } >"$PIN_FILE"
  chown "$U:$U" "$PIN_FILE"
  chmod 0644 "$PIN_FILE"
}

_kit_zsh_custom_src() {
  if [[ -n "${KIT_ZSH_CUSTOM_DIR:-}" && -d "${KIT_ZSH_CUSTOM_DIR}" ]]; then
    printf '%s\n' "${KIT_ZSH_CUSTOM_DIR}"
    return 0
  fi
  if [[ -n "${KIT_REPO_ROOT:-}" && -d "${KIT_REPO_ROOT}/scripts/kit-oh-my-zsh-custom" ]]; then
    printf '%s\n' "${KIT_REPO_ROOT}/scripts/kit-oh-my-zsh-custom"
    return 0
  fi
  if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != bash && "${BASH_SOURCE[0]}" != /dev/stdin ]]; then
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -d "${script_dir}/kit-oh-my-zsh-custom" ]]; then
      printf '%s\n' "${script_dir}/kit-oh-my-zsh-custom"
      return 0
    fi
  fi
  if [[ -d /opt/kit-oh-my-zsh-custom ]]; then
    printf '%s\n' /opt/kit-oh-my-zsh-custom
    return 0
  fi
  return 1
}

_install_kit_zsh_custom() {
  local src dest file
  src="$(_kit_zsh_custom_src)" || return 0
  dest="${OMZ_DIR}/custom"
  install -d -m 0755 -o "$U" -g "$U" "$dest"
  for file in "${src}"/*.zsh; do
    [[ -f "$file" ]] || continue
    install -m 0644 -o "$U" -g "$U" "$file" "${dest}/$(basename "$file")"
  done
  echo ">> oh-my-zsh: installed custom snippets from ${src}"
}

_write_kit_zshrc() {
  if [[ -f "$ZSHRC" ]] && grep -qF "$KIT_MARKER" "$ZSHRC" 2>/dev/null; then
    return 0
  fi

  if [[ -f "$ZSHRC" ]]; then
    backup="${ZSHRC}.bak-$(date +%Y%m%d%H%M%S)"
    cp -a "$ZSHRC" "$backup"
    chown "$U:$U" "$backup"
    echo ">> oh-my-zsh: backed up existing ${ZSHRC} to ${backup}"
  fi

  echo ">> oh-my-zsh: writing ${ZSHRC}"
  sudo -u "$U" tee "$ZSHRC" >/dev/null <<ZSHRC_EOF
${KIT_MARKER}

export ZSH="\${HOME}/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git aws docker kubectl helm)

source \${ZSH}/oh-my-zsh.sh

export PATH="\${HOME}/.local/bin:/snap/bin:\${PATH}"
export EDITOR=vim
export PROJECTS=~/projects
export GITLABBER_CLONE_METHOD="${GITLABBER_METHOD}"
export GITLAB_URL="${GITLAB_URL}"
export KIT_REPO="\${HOME}/projects/wsl-devops"
export BROWSER="\${HOME}/.local/bin/wsl-browser"
eval "\$(direnv hook zsh)"
ZSHRC_EOF
}

_install_oh_my_zsh
_install_kit_zsh_custom
_write_kit_zshrc
usermod -s /bin/zsh "$U" 2>/dev/null || true

if [[ -n "$OH_MY_ZSH_PIN" ]]; then
  echo ">> oh-my-zsh: done (pin=${OH_MY_ZSH_PIN}, commit=${OH_MY_ZSH_COMMIT:0:12})"
else
  echo ">> oh-my-zsh: done (commit=${OH_MY_ZSH_COMMIT:0:12})"
fi
