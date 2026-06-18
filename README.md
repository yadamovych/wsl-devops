# WSL DevOps Kit

Repeatable **Ubuntu 26.04 WSL** setup for daily DevOps work: **AWS CLI**, **OpenTofu**, **kubectl**, **Helm**, **Docker Desktop** integration.

**Version:** see [VERSION](VERSION) · changes in [CHANGELOG.md](CHANGELOG.md)

## What this does

- Installs Ubuntu 26.04 via official `.wsl` bundle (Method B)
- Provisions with **cloud-init** (user, systemd, packages, tools)
- Configures Windows `.wslconfig` (memory, CPUs, swap, NAT networking)
- One-command install and repeatable rebuild

## Quick start

```powershell
git clone https://github.com/yadamovych/wsl-devops.git
cd wsl-devops
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\new-secrets.ps1   # interactive prompt that creates config\secrets.local.ps1
.\scripts\install.ps1
```

`install.ps1` runs `scripts\preflight.ps1` first to verify everything a fresh Windows host needs
(Windows build, hardware virtualization, WSL/WSL2, Git for Windows, Docker Desktop, Windows
Terminal, and the secrets file) and will offer to create `config\secrets.local.ps1` interactively
if it is missing. Docker Desktop / Windows Terminal are reported as warnings, not blockers. You can
still create it manually instead: `copy config\secrets.local.ps1.example config\secrets.local.ps1`
then edit the password / git identity.

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
| [config/kit.config.ps1](config/kit.config.ps1) | Distro name, timezone, WSL RAM/CPUs/swap, gitlabber clone method | Yes |
| [config/tool-versions.ps1](config/tool-versions.ps1) | Pinned tool versions (asdf, aws-cli, glab, gitlabber, helm, kubectl, opentofu) | Yes |
| [config/wsl.config.template](config/wsl.config.template) | `.wslconfig` template (VM resources, experimental flags) | Yes |
| [config/secrets.local.ps1.example](config/secrets.local.ps1.example) | Template for `config/secrets.local.ps1` (password, git identity) | Yes |
| `config/secrets.local.ps1` | Your password + git identity (created locally) | **No** (gitignored) |
| [cloud-init/Ubuntu-DevOps.user-data.template](cloud-init/Ubuntu-DevOps.user-data.template) | Provisioning template | Yes |

## Manual steps after install

[docs/manual-steps.md](docs/manual-steps.md) — AWS SSO, Docker Desktop, SSH keys, **gitlabber** group clone (`-T`).

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/install.ps1` | Full install (preflight → cloud-init → WSL distro) |
| `scripts/verify.ps1` | Smoke-test tools in WSL + print helpful commands |
| `scripts/update-tools.ps1` | Bump pinned tools in an **existing** distro (no rebuild) |
| `scripts/check-tool-updates.ps1` | Compare `tool-versions.ps1` pins to upstream releases |
| `scripts/preflight.ps1` | Prerequisite check only (Git for Windows + credential helper, WSL, secrets, …) |

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
