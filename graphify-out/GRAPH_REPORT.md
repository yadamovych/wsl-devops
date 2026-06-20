# Graph Report - .  (2026-06-20)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 98 nodes · 89 edges · 32 communities (20 shown, 12 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8d387d24`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 31|Community 31]]

## God Nodes (most connected - your core abstractions)
1. `Get-KitPrerequisite()` - 8 edges
2. `WSL` - 7 edges
3. `Repeat Install Checklist` - 5 edges
4. `Test-KitCommand()` - 4 edges
5. `install-oh-my-zsh.sh script` - 4 edges
6. `Install Script` - 4 edges
7. `Manual Post-Provision Steps` - 4 edges
8. `New-KitSecrets()` - 3 edges
9. `Request-KitSecrets()` - 3 edges
10. `Get-KitWslInfo()` - 3 edges

## Surprising Connections (you probably didn't know these)
- `Repeat Install Checklist` --references--> `Uninstall Script`  [EXTRACTED]
  checklists/repeat-install.md → scripts/uninstall.ps1
- `Repeat Install Checklist` --references--> `Verify Script`  [EXTRACTED]
  checklists/repeat-install.md → scripts/verify.ps1
- `Repeat Install Checklist` --references--> `Update Tools Script`  [EXTRACTED]
  checklists/repeat-install.md → scripts/update-tools.ps1
- `Repeat Install Checklist` --references--> `Check Tool Updates Script`  [EXTRACTED]
  checklists/repeat-install.md → scripts/check-tool-updates.ps1
- `Fresh Install Checklist` --references--> `Install Script`  [EXTRACTED]
  checklists/fresh-install.md → scripts/install.ps1

## Import Cycles
- None detected.

## Communities (32 total, 12 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.18
Nodes (13): Fresh Install Checklist, Repeat Install Checklist, Docker Desktop, Manual Post-Provision Steps, Prerequisites, Git for Windows, Check Tool Updates Script, Install Script (+5 more)

### Community 1 - "Community 1"
Cohesion: 0.31
Nodes (12): ConvertTo-Ps1SingleQuoted(), Get-KitGitCredentialHelperPath(), Get-KitOsInfo(), Get-KitPrerequisite(), Get-KitSecretsStatus(), Get-KitWslInfo(), New-KitSecrets(), Request-KitSecrets() (+4 more)

### Community 2 - "Community 2"
Cohesion: 0.29
Nodes (5): Compare-PinnedVersion(), Get-SnapInfo(), Get-SnapLatestStableTrack(), Get-SnapStableVersion(), Normalize-VersionString()

### Community 3 - "Community 3"
Cohesion: 0.25
Nodes (4): Docker, systemd, WSL, wsl.config

### Community 4 - "Community 4"
Cohesion: 0.60
Nodes (4): install-oh-my-zsh.sh script, _install_kit_zsh_custom(), _install_oh_my_zsh(), _write_kit_zshrc()

### Community 5 - "Community 5"
Cohesion: 0.40
Nodes (5): scripts/KitSecrets.psm1, scripts/KitTemplate.psm1, scripts/new-secrets.ps1, scripts/preflight.ps1, scripts/render-templates.ps1

### Community 6 - "Community 6"
Cohesion: 0.50
Nodes (3): update-tools.sh script, DEBIAN_FRONTEND, PATH

### Community 7 - "Community 7"
Cohesion: 0.67
Nodes (3): scripts/install.ps1, scripts/new-secrets.ps1, scripts/preflight.ps1

## Knowledge Gaps
- **30 isolated node(s):** `add-snap-path.sh script`, `install-wsl-browser.sh script`, `install-wsl-editors.sh script`, `update-tools.sh script`, `PATH` (+25 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Are the 2 inferred relationships involving `WSL` (e.g. with `Docker` and `systemd`) actually correct?**
  _`WSL` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `add-snap-path.sh script`, `install-wsl-browser.sh script`, `install-wsl-editors.sh script` to the rest of the system?**
  _30 weakly-connected nodes found - possible documentation gaps or missing edges._