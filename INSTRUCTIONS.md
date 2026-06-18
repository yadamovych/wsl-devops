# WSL DevOps Kit — Instructions

This file mirrors [README.md](README.md). Start there for the full guide.

## Repeat install (any Windows PC)

1. Clone: `git clone https://github.com/yadamovych/wsl-devops.git`
2. Secrets: `copy config\secrets.local.ps1.example config\secrets.local.ps1` → edit
3. Install: `.\scripts\install.ps1`
4. Manual: [checklists/repeat-install.md](checklists/repeat-install.md)

## Update tools (existing distro)

```powershell
.\scripts\update-tools.ps1
```

See [docs/troubleshooting.md](docs/troubleshooting.md#upgrading-a-pinned-tool-version).

## Full rebuild

```powershell
.\scripts\uninstall.ps1
.\scripts\install.ps1
```
