# Fresh Install Checklist

Use this on a **new Windows PC** before running `scripts\install.ps1`.

## Windows prerequisites

- [ ] Windows 11 or Windows 10 21H2+
- [ ] Virtualization enabled in BIOS/UEFI
- [ ] WSL2 updated: `wsl --update` and `wsl --set-default-version 2`
- [ ] [Git for Windows](https://git-scm.com/download/win) installed
- [ ] [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed (WSL2 engine)
- [ ] [Windows Terminal](https://aka.ms/terminal) installed (recommended)

## Repo setup

- [ ] `git clone https://github.com/yadamovych/wsl-devops.git`
- [ ] `copy config\secrets.local.ps1.example config\secrets.local.ps1`
- [ ] Edit `config\secrets.local.ps1` (password, git name/email)
- [ ] Optionally edit `config\kit.config.ps1` (timezone, WSL memory)

## Install

- [ ] `Set-ExecutionPolicy -Scope Process Bypass`
- [ ] `.\scripts\install.ps1`

## After install

See [repeat-install.md](repeat-install.md).
