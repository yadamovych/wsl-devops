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
- [ ] `code ~/projects` (VS Code Remote-WSL)

## Rebuild same machine

```powershell
git pull
.\scripts\uninstall.ps1
.\scripts\install.ps1
```
