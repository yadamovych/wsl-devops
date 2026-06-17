# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-06-17

### Added
- Interactive secrets creation: `scripts/new-secrets.ps1` prompts for the Linux password
  and git identity and writes `config/secrets.local.ps1` (no manual file copy needed).
- Prerequisite check `scripts/preflight.ps1` (run automatically at the start of
  `scripts/install.ps1`) verifying everything a fresh Windows host needs: PowerShell >= 5.1,
  Windows OS + build >= 19044, hardware virtualization, WSL, modern WSL2/Store build,
  Git for Windows, Docker Desktop (running + WSL integration), Windows Terminal, and the
  kit secrets file.
- `scripts/render-templates.ps1` now offers to create missing/`CHANGE_ME` secrets interactively,
  and otherwise fails with actionable guidance.
- Reusable modules `scripts/KitTemplate.psm1` and `scripts/KitSecrets.psm1`.
- Cross-platform Pester test suite under `tests/` (runs on Linux/macOS/Windows without WSL).

### Fixed
- cloud-init bootstrap: create the `docker` group (`groupadd -f docker`) before
  `usermod -aG docker`, eliminating `usermod: group 'docker' does not exist`
  (only `docker-ce-cli` is installed, which never creates the group).
- `.wslconfig`: removed `dnsTunneling=true`, which only emitted the harmless
  `wsl: DNS Tunneling is not supported` warning on unsupported hosts (it defaults to `true`
  on Windows 11 22H2+ anyway).

### Changed
- README corrected (NAT not "mirrored" networking; complete configuration table; valid links)
  and documentation updated for the new scripts and the DNS-tunneling behavior.

## [1.0.0] - Initial release

### Added
- Ubuntu 26.04 WSL provisioning via official `.wsl` bundle + cloud-init.
- PowerShell install/uninstall/verify/deploy scripts and `.wslconfig` / cloud-init templates.
- Tooling: AWS CLI, OpenTofu, kubectl, Helm, glab, gitlabber, asdf, Docker CLI.

[1.1.0]: https://github.com/yadamovych/wsl-devops/releases/tag/v1.1.0
[1.0.0]: https://github.com/yadamovych/wsl-devops/releases/tag/v1.0.0
