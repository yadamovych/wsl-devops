#!/usr/bin/env bash
# Install a BROWSER helper for WSL (AWS SSO login, etc.).
# Safe when appendWindowsPath=false — opens URLs in the Windows default browser.
#
# Invoked from cloud-init bootstrap and scripts/update-tools.sh.

set -euo pipefail

U="${1:-${LINUX_USERNAME:-}}"
if [[ -z "$U" ]]; then
  echo "Usage: $0 <linux-username>" >&2
  exit 1
fi

HOME_DIR="/home/$U"
BIN_DIR="$HOME_DIR/.local/bin"
BROWSER_BIN="$BIN_DIR/wsl-browser"

install -d -m 0755 -o "$U" -g "$U" "$BIN_DIR"

cat <<'BROWSER' >"$BROWSER_BIN"
#!/usr/bin/env bash
# Open a URL in the Windows default browser from WSL.
set -euo pipefail
url="${1:?URL required}"
if command -v wslview >/dev/null 2>&1; then
  exec wslview "$url"
fi
exec /mnt/c/Windows/System32/cmd.exe /c start "" "$url"
BROWSER

chmod 0755 "$BROWSER_BIN"
chown "$U:$U" "$BROWSER_BIN"
echo ">> wsl-browser: installed $BROWSER_BIN"
