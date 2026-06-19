# Plain WSL shells start in ~/projects; IDE terminals keep the workspace cwd.
if [[ "${TERM_PROGRAM:-}" != "vscode" && -z "${VSCODE_IPC_HOOK_CLI:-}" ]]; then
  if [[ "$PWD" == "$HOME" ]]; then
    cd "${PROJECTS:-$HOME/projects}" 2>/dev/null || true
  fi
fi
