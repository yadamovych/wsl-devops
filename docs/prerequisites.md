# Prerequisites

## Windows

- Windows 11 or Windows 10 version 21H2+
- Virtualization enabled in BIOS/UEFI
- Administrator access for first WSL setup

## Required software

| Tool | Purpose |
|------|---------|
| WSL2 | Linux environment — `wsl --update` |
| Git for Windows | Clone repo on Windows; **`git-credential-wincred.exe`** for WSL HTTPS git (GitLab/GitHub). Install from [gitforwindows.org](https://gitforwindows.org/). `preflight.ps1` verifies both `git` and the helper binary. |
| Docker Desktop | Containers via WSL integration (do not install docker-ce in WSL) |

## Recommended

- Windows Terminal
- VS Code + Remote - WSL extension

## PowerShell

Run scripts with:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

## WSL version check

```powershell
wsl --version
wsl --set-default-version 2
```

WSL from the Microsoft Store is recommended (supports systemd on Ubuntu 22.04+).
