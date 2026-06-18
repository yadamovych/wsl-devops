# Troubleshooting

## cloud-init did not run

Cloud-init only runs on **first boot**. If you saw the OOBE username/password prompt, cloud-init was skipped.

Fix:

```powershell
.\scripts\uninstall.ps1
.\scripts\deploy-cloud-init.ps1
wsl --install --from-file $env:USERPROFILE\Downloads\ubuntu-26.04-wsl-amd64.wsl --name Ubuntu-DevOps --no-launch
wsl -d Ubuntu-DevOps
```

Always use `--no-launch` and deploy cloud-init **before** first launch.

## systemd not running

Ensure `/etc/wsl.conf` contains `[boot] systemd=true`, then:

```powershell
wsl --shutdown
wsl -d Ubuntu-DevOps
```

Inside WSL: `systemctl is-system-running`

## Docker command not found in WSL

Enable WSL integration in Docker Desktop for **Ubuntu-DevOps**. Do not install Docker Engine inside WSL when using Docker Desktop.

## "wsl: DNS Tunneling is not supported"

Harmless warning, safe to ignore. DNS tunneling requires Windows 11 22H2+ and WSL 2.0.0+;
on Windows 10 or older WSL builds WSL ignores the setting and uses normal DNS (the generated
`/etc/resolv.conf`). The kit does not set `dnsTunneling` (it defaults to `true` on supported
Windows 11), so a fresh `.wslconfig` does not trigger the warning. If you want it on explicitly,
add `dnsTunneling=true` under `[wsl2]` in `config/wsl.config.template`, re-deploy, then
`wsl --shutdown`.

## Install to a different drive (not C:)

By default WSL stores the distro's `ext4.vhdx` under `%LOCALAPPDATA%` on `C:`. To install
elsewhere, set `$WslInstallLocation` in `config/kit.config.ps1` before running `install.ps1`:

```powershell
# config/kit.config.ps1
$WslInstallLocation = "D:\WSL\Ubuntu-DevOps"
```

`install.ps1` creates the folder and passes `wsl --install --location`. Requires **WSL 2.4.4+**
(`wsl --version` to check). `--from-file` is kept so cloud-init still provisions on first boot.

To move an **existing** distro instead: `wsl --export`, `wsl --unregister`, then
`wsl --import <name> D:\WSL\<name> <file>.tar` (note: import-based distros do not re-run cloud-init).
A global default for future installs can also be set in `%UserProfile%\.wslconfig` under
`[general]` with `distributionInstallPath=D:\WSL`.

## Slow file operations

Keep projects under `~/projects` in the Linux filesystem. Avoid `/mnt/c/` for active development.

## SHA256 verification failed

Re-download the image from [releases.ubuntu.com/26.04](https://releases.ubuntu.com/26.04/) or delete the local file and re-run `install.ps1`.

## Config changes not applied

After editing `.wslconfig` or `/etc/wsl.conf`:

```powershell
wsl --shutdown
# wait ~8 seconds
wsl -d Ubuntu-DevOps
```

## Re-provision from scratch

```powershell
git pull
.\scripts\uninstall.ps1
.\scripts\install.ps1
```

## Upgrading a pinned tool version

Edit `config/tool-versions.ps1`, bump the version, commit, push, then reprovision:

```powershell
# 1. Edit config\tool-versions.ps1 — e.g. $AsdfVersion = '0.20.0'
# 2. Commit and push
git add config\tool-versions.ps1
git commit -m "chore: bump asdf to 0.20.0"
git push
# 3. Reprovision
.\scripts\uninstall.ps1
.\scripts\install.ps1
```

## Adding a new tool

1. Add a `$ToolVersion` variable to `config/tool-versions.ps1`
2. Add `'{{TOOL_VERSION}}' = $ToolVersion` to `$Replacements` in `scripts/render-templates.ps1`
3. Add a labeled install block to `cloud-init/Ubuntu-DevOps.user-data.template` using `{{TOOL_VERSION}}`
4. Add a version check to `scripts/verify.ps1`
