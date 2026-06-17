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

## VS Code

```bash
code ~/projects
```

Recommended extensions: Remote - WSL, Docker, HCL/Terraform syntax, YAML, AWS Toolkit.
