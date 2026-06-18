# Kit environment (ported from linux-dev-env, specific paths removed).
export AWS_PAGER=
export GPG_TTY="${GPG_TTY:-$(tty)}"

# Repo checkout used by kit scripts (clone wsl-devops here for cdwsldevops).
export KIT_REPO="${KIT_REPO:-${HOME}/projects/wsl-devops}"
