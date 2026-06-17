# AGENTS.md

## Cursor Cloud specific instructions

This repo is the **WSL DevOps Kit**: Windows PowerShell scripts + a cloud-init template that
provision an Ubuntu 26.04 **WSL** distro on a Windows host. It is not a server/web app and has
no long-running service to start. The cloud agent runs on Linux, so keep the following in mind.

### Toolchain (installed by the update script)
- `pwsh` (PowerShell 7) — runs/parses the `.ps1` scripts.
- `PSScriptAnalyzer` (PowerShell linter, the de-facto standard for this repo).
- `python3` (preinstalled, has PyYAML) — handy for validating rendered cloud-init YAML.

### Lint
- `pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path . -Recurse"`
- Expect **0 errors**. There are pre-existing **Warning**-level findings (mostly
  `PSAvoidUsingWriteHost` and `PSUseDeclaredVarsMoreThanAssignments`); these are stylistic and
  not failures.

### Tests
- Pester v5 suite in `tests/`. Run from repo root: `pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -Output Detailed"`.
- The suite validates the platform-agnostic rendering logic (`scripts/KitTemplate.psm1`) plus an
  end-to-end render via `scripts/render-templates.ps1`, so it runs on Linux without WSL.
- The integration test temporarily writes `config/secrets.local.ps1` (backing up/restoring any
  existing one), so it is self-contained and does not require pre-existing secrets.

### Run (core functionality that works on Linux)
- `scripts/render-templates.ps1` is the heart of the kit: it substitutes `{{PLACEHOLDER}}`
  values from `config/kit.config.ps1` + `config/tool-versions.ps1` + `config/secrets.local.ps1`
  into the cloud-init and `.wslconfig` templates, writing results to `.cloud-init-rendered/`.
  The reusable substitution logic lives in `scripts/KitTemplate.psm1` (`Expand-KitTemplate`).
- It **requires** `config/secrets.local.ps1` (gitignored). Create it from
  `config/secrets.local.ps1.example` and set `LinuxPassword` to anything other than `CHANGE_ME`
  (the script throws otherwise).
- Run it with: `pwsh -NoProfile -File scripts/render-templates.ps1`.
- Validate the rendered cloud-init with:
  `python3 -c "import yaml; yaml.safe_load(open('.cloud-init-rendered/Ubuntu-DevOps.user-data'))"`
  and confirm no `{{...}}` placeholders remain.

### What cannot run on this Linux VM (Windows-only)
- `scripts/install.ps1`, `scripts/verify.ps1`, `scripts/uninstall.ps1`,
  `scripts/deploy-cloud-init.ps1`, `scripts/deploy-wslconfig.ps1` invoke the Windows `wsl.exe`
  command and/or use `$env:USERPROFILE`. They only work on a real Windows host with WSL2.
  Do not expect them to succeed here; `render-templates.ps1` is the only end-to-end runnable
  piece on Linux (the deploy scripts call it before copying to Windows paths).

### Non-obvious gotcha
- PowerShell 7 on Linux automatically normalizes the Windows-style backslash paths used
  throughout the scripts (e.g. `Join-Path $RepoRoot 'config\kit.config.ps1'` resolves to
  `config/kit.config.ps1`), so render-templates works unmodified on Linux.
