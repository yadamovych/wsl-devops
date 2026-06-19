# Kit shell environment defaults (overridden in .bashrc / .zshrc from kit.config.ps1).
export AWS_PAGER=
export GPG_TTY="${GPG_TTY:-$(tty)}"
export BROWSER="${BROWSER:-${HOME}/.local/bin/wsl-browser}"
export GITLAB_URL="${GITLAB_URL:-https://gitlab.com}"
export KIT_REPO="${KIT_REPO:-${HOME}/projects/wsl-devops}"
