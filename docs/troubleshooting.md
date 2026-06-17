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
