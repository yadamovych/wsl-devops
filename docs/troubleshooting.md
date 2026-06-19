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

Edit `config/tool-versions.ps1`, bump the version, commit, then apply the change.

### In-place update (recommended)

Refreshes only the kit CLI tools inside your existing distro (~1–2 minutes).
Keeps your home directory, SSH keys, and project checkouts.

```powershell
# 1. Edit config\tool-versions.ps1 — e.g. $AsdfVersion = '0.20.0'
# 2. Commit and push (optional but keeps the repo in sync)
git add config\tool-versions.ps1
git commit -m "chore: bump asdf to 0.20.0"
git push
# 3. Render + run the WSL update script
.\scripts\update-tools.ps1
```

`update-tools.ps1` calls `render-templates.ps1` (writes `.cloud-init-rendered/tool-versions.env`)
then runs `scripts/update-tools.sh` inside WSL with `sudo`.

You can also run the shell script directly inside WSL after rendering:

```bash
sudo bash ~/projects/wsl-devops/scripts/update-tools.sh
```

### Full reprovision (nuclear option)

Rebuilds the distro from the official `.wsl` image. Use when cloud-init itself changed
or the distro is broken.

```powershell
.\scripts\uninstall.ps1
.\scripts\install.ps1
```

## Adding a new tool

1. Add a `$ToolVersion` variable to `config/tool-versions.ps1`
2. Add `'{{TOOL_VERSION}}' = $ToolVersion` to `$Replacements` in `scripts/render-templates.ps1`
3. Add a labeled install block to `cloud-init/Ubuntu-DevOps.user-data.template` using `{{TOOL_VERSION}}`
4. Add a version check to `scripts/verify.ps1`

## Git HTTPS auth fails in WSL

WSL git is configured to use Git for Windows' credential helper
(`git-credential-wincred.exe`). If `git clone` over HTTPS fails:

1. Install or reinstall [Git for Windows](https://gitforwindows.org/) on the Windows host.
2. Run `.\scripts\preflight.ps1` — the **Git for Windows (git + WSL credential helper)** check must pass.
3. Retry `git clone` in WSL; complete the Windows credential prompt on first use.

## gitlabber wrote my token into `.git/config`

Without `-T`, gitlabber embeds the token in each repo's `remote.origin.url`. Fix:

```bash
# Future clones — always use -T
gitlabber -T -u "$GITLAB_URL" -i '/your-group/**' ~/projects

# Existing repo — strip token from remote URL (then git pull uses the Windows credential helper)
git -C path/to/repo remote set-url origin "$(git -C path/to/repo remote get-url origin | sed -E 's#https://[^@]+@#https://#')"
```

See [manual-steps.md](manual-steps.md#gitlab-group-clone-gitlabber).

## Check for newer tool versions

```powershell
.\scripts\check-tool-updates.ps1
```

Compares pins in `config/tool-versions.ps1` to upstream (GitHub, PyPI, snap tracks). Use
`-FailIfUpdates` to exit non-zero when updates are available (e.g. in CI).
