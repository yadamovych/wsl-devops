# Manual Post-Provision Steps

These steps require interactive login or Windows GUI and are intentionally not in cloud-init.

## AWS authentication

```bash
aws configure sso
# or
aws configure --profile dev

aws sts get-caller-identity
```

## Docker Desktop

1. Open Docker Desktop → Settings → General → **Use the WSL 2 based engine**
2. Settings → Resources → WSL Integration → enable **Ubuntu-DevOps**
3. Do **not** install `docker-ce` inside WSL

Verify:

```bash
docker version
docker compose version
docker run --rm hello-world
```

## SSH public key

```bash
cat ~/.ssh/id_ed25519.pub
```

Add the key to GitHub, GitLab, or AWS as needed.

## Git authentication (WSL → Windows)

Cloud-init configures WSL git to use Git for Windows' credential helper:

`/mnt/c/Program Files/Git/mingw64/libexec/git-core/git-credential-wincred.exe`

That lets `git clone` / `git pull` over HTTPS in WSL prompt through Windows (GitLab, GitHub, etc.).
**Requires [Git for Windows](https://gitforwindows.org/)** on the host — `preflight.ps1` checks for
`git` on PATH and `git-credential-wincred.exe`.

After the first HTTPS git operation, sign in when Windows prompts you; credentials are cached.

## GitLab group clone (gitlabber)

Clone an entire group **with subgroups** into `~/projects`. Use a GitLab personal access token
with `read_api` and `read_repository` scopes.

```bash
# Optional: set token for this shell (not saved in shell history if you use read -s)
read -rsp "GitLab token: " GITLAB_TOKEN
echo
export GITLAB_TOKEN

# Preview the tree (no clone)
gitlabber -p -u https://gitlab.com -i '/your-group/**'

# Clone group + subgroups (-T keeps the token out of each repo's .git/config)
gitlabber -T -u https://gitlab.com -i '/your-group/**' ~/projects
```

**Always pass `-T` (`--hide-token`)** when using HTTP — without it, gitlabber embeds the token in
every repo's `remote.origin.url` inside `.git/config`.

Alternatives:

- **SSH clones:** `gitlabber -m ssh ...` or set `$GitlabberCloneMethod = "ssh"` in
  `config/kit.config.ps1` before install (SSH key must be in GitLab).
- **Store token once:** `gitlabber --store-token -u https://gitlab.com` (still use `-T` when cloning).

After `git pull` on existing repos, the Windows credential helper above handles auth. To strip a
token already saved in a remote URL:

```bash
git -C path/to/repo remote set-url origin "$(git -C path/to/repo remote get-url origin | sed -E 's#https://[^@]+@#https://#')"
```

## VS Code / Cursor (from WSL)

The kit installs `code` and `cursor` in `~/.local/bin`. They launch the **Windows** editor
for the current WSL folder (works with `appendWindowsPath=false`).

**Windows host prerequisites:**

- [VS Code](https://code.visualstudio.com/) + **Remote - WSL** extension, or
- [Cursor](https://cursor.com/) + Remote WSL support  
- In Cursor: `Ctrl+Shift+P` → **Shell Command: Install 'cursor' command in PATH**

```bash
cd ~/projects/your-repo
code .      # VS Code
cursor .    # Cursor
```

On an **existing** distro (before reprovision), install the wrappers with:

```bash
sudo bash /mnt/c/Users/<you>/Projects/wsl-devops/scripts/install-wsl-editors.sh devops
```

Or from Windows: `.\scripts\update-tools.ps1` (installs wrappers after refreshing tools).

Recommended extensions: Remote - WSL, Docker, HCL/Terraform syntax, YAML, AWS Toolkit.
