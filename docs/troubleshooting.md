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
