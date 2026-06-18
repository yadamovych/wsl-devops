# Repeat Install Checklist

Run after every `scripts\install.ps1` (new machine or rebuild).

## Automated (install.ps1)

- [ ] cloud-init deployed to `%USERPROFILE%\.cloud-init\`
- [ ] Ubuntu 26.04 installed with `--no-launch`
- [ ] `.wslconfig` applied
- [ ] `scripts\verify.ps1` passed

## Manual (~10 min)

- [ ] Docker Desktop → Settings → Resources → WSL Integration → **Ubuntu-DevOps** enabled
- [ ] `docker run --rm hello-world`
- [ ] `aws configure sso` (or named profile)
- [ ] `aws sts get-caller-identity`
- [ ] `cat ~/.ssh/id_ed25519.pub` → add to GitHub/GitLab
- [ ] Clone GitLab group (optional): `gitlabber -T -u https://gitlab.com -i '/your-group/**' ~/projects`
      (see [docs/manual-steps.md](../docs/manual-steps.md#gitlab-group-clone-gitlabber))
- [ ] `code ~/projects` (VS Code Remote-WSL)

## Tool version bumps (existing distro)

No full rebuild needed — edit `config/tool-versions.ps1`, then:

```powershell
.\scripts\check-tool-updates.ps1   # optional: see what is upstream
.\scripts\update-tools.ps1
.\scripts\verify.ps1
```

## Rebuild same machine

```powershell
git pull
.\scripts\uninstall.ps1
.\scripts\install.ps1
```
