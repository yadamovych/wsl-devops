# Kit aliases and helpers (ported from linux-dev-env/script/oh-my-zsh-custom).

# Navigation
alias cdprojects='cd "${PROJECTS:-${HOME}/projects}"'
alias cdwsldevops='cd "${KIT_REPO:-${HOME}/projects/wsl-devops}"'
alias cdlinuxdevenv='cdwsldevops'

# Dev tools
alias k='kubectl'
alias c='clear'
alias h='history'
alias path='echo -e ${PATH//:/\\n}'
alias update='sudo apt update && sudo apt full-upgrade -y'

# asdf: set JAVA_HOME when the java plugin is active
asdf_java_home() {
  local asdf_java_path
  if command -v asdf >/dev/null 2>&1 && asdf current java >/dev/null 2>&1; then
    asdf_java_path="$(asdf which java)" || return $?
    export JAVA_HOME="${asdf_java_path%/*/*}"
  fi
}

# List blobs >= 1 MiB in the current repo
git-get-large-files() {
  git rev-list --objects --all |
    git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
    sed -n 's/^blob //p' |
    awk '$2 >= 2^20' |
    sort --numeric-sort --key=2 |
    cut -c 1-12,41- |
    $(command -v gnumfmt || echo numfmt) --field=2 --to=iec-i --suffix=B --padding=7 --round=nearest
}
