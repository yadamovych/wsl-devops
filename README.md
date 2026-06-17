# WSL DevOps Kit

Repeatable **Ubuntu 26.04 WSL** setup for daily DevOps work: **AWS CLI**, **OpenTofu**, **kubectl**, **Helm**, **Docker Desktop** integration.

**Version:** see [VERSION](VERSION)

## What this does

- Installs Ubuntu 26.04 via official `.wsl` bundle (Method B)
- Provisions with **cloud-init** (user, systemd, packages, tools)
- Configures Windows `.wslconfig` (memory, mirrored networking)
- One-command install and repeatable rebuild

## Quick start

```powershell
git clone https://github.com/yadamovych/wsl-devops.git
cd wsl-devops
copy config\secrets.local.ps1.example config\secrets.local.ps1
# Edit config\secrets.local.ps1 — password, git name, email
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\install.ps1
```

Then complete [checklists/repeat-install.md](checklists/repeat-install.md) (AWS SSO, Docker WSL toggle, SSH key).

## First time on a new PC

See [checklists/fresh-install.md](checklists/fresh-install.md) and [docs/prerequisites.md](docs/prerequisites.md).

## Reinstall

```powershell
git pull
.\scripts\uninstall.ps1
.\scripts\install.ps1
```

## Configuration

| File | Purpose | Commit? |
|------|---------|---------|
| [config/kit.config.ps1](config/kit.config.ps1) | Distro name, timezone, WSL RAM | Yes |
| [config/secrets.local.ps1](config/secrets.local.ps1) | Password, git identity | **No** (gitignored) |
| [cloud-init/Ubuntu-DevOps.user-data.template](cloud-init/Ubuntu-DevOps.user-data.template) | Provisioning template | Yes |

## Manual steps after install

[docs/manual-steps.md](docs/manual-steps.md)

## Troubleshooting

[docs/troubleshooting.md](docs/troubleshooting.md)

## Validate (any OS, no WSL needed)

The template-rendering logic is cross-platform and covered by a Pester suite. With
[PowerShell 7](https://github.com/PowerShell/PowerShell) + `Pester` installed:

```powershell
Invoke-Pester -Path ./tests -Output Detailed
```

This renders the cloud-init / `.wslconfig` templates and asserts placeholder substitution
without touching WSL. `scripts/install.ps1` and friends still require Windows + WSL2.

## Golden rules

1. Store code in `~/projects` — not `/mnt/c/`
2. Enable systemd (done via cloud-init)
3. Do not install `docker-ce` when using Docker Desktop
4. Use `tofu`, not HashiCorp `terraform` CLI

## License

MIT (add license file if needed)
