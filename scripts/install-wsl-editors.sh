#!/usr/bin/env bash
# Install WSL wrappers for VS Code and Cursor (code . / cursor .).
# Safe when appendWindowsPath=false — calls the Windows host binaries via /mnt/c.
#
# Invoked from cloud-init bootstrap and scripts/update-tools.sh.

set -euo pipefail

U="${1:-${LINUX_USERNAME:-}}"
if [[ -z "$U" ]]; then
  echo "Usage: $0 <linux-username>" >&2
  exit 1
fi

HOME_DIR="/home/$U"
LIB_DIR="$HOME_DIR/.local/lib"
BIN_DIR="$HOME_DIR/.local/bin"

install -d -m 0755 -o "$U" -g "$U" "$LIB_DIR" "$BIN_DIR"

cat <<'LIB' >"$LIB_DIR/kit-wsl-editors.sh"
# Shared helpers for kit WSL editor CLI wrappers.
_kit_win_cmd() {
  local candidate
  for candidate in \
    /mnt/c/Windows/System32/cmd.exe \
    /mnt/c/WINDOWS/System32/cmd.exe \
    cmd.exe; do
    if [[ -x "$candidate" ]] || [[ -e "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

_kit_win_user() {
  local cmd user
  cmd="$(_kit_win_cmd)" || return 1
  user="$("$cmd" /c echo %USERNAME% 2>/dev/null | tr -d '\r\n')"
  if [[ -n "$user" ]]; then
    printf '%s' "$user"
    return 0
  fi
  for candidate in \
    /mnt/c/Windows/System32/whoami.exe \
    /mnt/c/WINDOWS/System32/whoami.exe; do
    if [[ -e "$candidate" ]]; then
      user="$("$candidate" 2>/dev/null | tr -d '\r\n' | sed 's/.*\\//')"
      if [[ -n "$user" ]]; then
        printf '%s' "$user"
        return 0
      fi
    fi
  done
  return 1
}

_kit_win_home() {
  local user
  user="$(_kit_win_user)" || return 1
  printf '/mnt/c/Users/%s' "$user"
}

_kit_first_existing() {
  local candidate
  for candidate in "$@"; do
    if [[ -e "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

_kit_open_vscode() {
  local home bin
  home="$(_kit_win_home)" || home=
  bin="$(_kit_first_existing \
    ${home:+"${home}/AppData/Local/Programs/Microsoft VS Code/bin/code"} \
    ${home:+"${home}/AppData/Local/Programs/Microsoft VS Code/bin/code.cmd"} \
    "/mnt/c/Program Files/Microsoft VS Code/bin/code" \
    "/mnt/c/Program Files/Microsoft VS Code/bin/code.cmd" \
  )" || {
    echo "VS Code not found on the Windows host. Install VS Code and the Remote - WSL extension." >&2
    return 127
  }
  exec "$bin" "$@"
}

_kit_open_cursor() {
  local home bin
  home="$(_kit_win_home)" || home=
  bin="$(_kit_first_existing \
    ${home:+"${home}/AppData/Local/Programs/cursor/resources/app/bin/cursor"} \
    ${home:+"${home}/AppData/Local/Programs/cursor/resources/app/bin/cursor.cmd"} \
    ${home:+"${home}/AppData/Local/Programs/Cursor/resources/app/bin/cursor"} \
    ${home:+"${home}/AppData/Local/Programs/Cursor/resources/app/bin/cursor.cmd"} \
    ${home:+"${home}/AppData/Local/Programs/cursor/bin/cursor.cmd"} \
    ${home:+"${home}/AppData/Local/Programs/Cursor/bin/cursor.cmd"} \
  )" || {
    echo "Cursor not found on the Windows host. Install Cursor and run: Shell Command: Install 'cursor' command in PATH." >&2
    return 127
  }
  exec "$bin" "$@"
}
LIB
chown "$U:$U" "$LIB_DIR/kit-wsl-editors.sh"
chmod 0644 "$LIB_DIR/kit-wsl-editors.sh"

cat <<'WRAP' >"$BIN_DIR/code"
#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
source "${HOME}/.local/lib/kit-wsl-editors.sh"
_kit_open_vscode "$@"
WRAP
chown "$U:$U" "$BIN_DIR/code"
chmod 0755 "$BIN_DIR/code"

cat <<'WRAP' >"$BIN_DIR/cursor"
#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
source "${HOME}/.local/lib/kit-wsl-editors.sh"
_kit_open_cursor "$@"
WRAP
chown "$U:$U" "$BIN_DIR/cursor"
chmod 0755 "$BIN_DIR/cursor"
