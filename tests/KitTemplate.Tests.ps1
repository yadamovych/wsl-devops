#Requires -Version 5.1
# Pester v5 tests. Run from repo root: Invoke-Pester ./tests
# These validate the platform-agnostic template-rendering logic, so they run on
# Linux/macOS/Windows without needing WSL.

BeforeAll {
    $script:RepoRoot   = Split-Path -Parent $PSScriptRoot
    $script:ScriptsDir = Join-Path $script:RepoRoot 'scripts'
    Import-Module (Join-Path $script:ScriptsDir 'KitTemplate.psm1') -Force
}

Describe 'Expand-KitTemplate (unit)' {
    BeforeEach {
        $script:tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $script:tmp | Out-Null
    }
    AfterEach {
        if (Test-Path $script:tmp) { Remove-Item -Recurse -Force $script:tmp }
    }

    It 'substitutes every placeholder' {
        $in  = Join-Path $script:tmp 'in.txt'
        $out = Join-Path $script:tmp 'out.txt'
        Set-Content -Path $in -Value 'hello {{NAME}} from {{PLACE}}' -NoNewline
        Expand-KitTemplate -Path $in -OutPath $out -Replacements @{ '{{NAME}}' = 'world'; '{{PLACE}}' = 'kyiv' }
        (Get-Content -Raw $out) | Should -BeExactly 'hello world from kyiv'
    }

    It 'coerces non-string replacement values (e.g. integers)' {
        $in  = Join-Path $script:tmp 'in.txt'
        $out = Join-Path $script:tmp 'out.txt'
        Set-Content -Path $in -Value 'processors={{N}}' -NoNewline
        Expand-KitTemplate -Path $in -OutPath $out -Replacements @{ '{{N}}' = 4 }
        (Get-Content -Raw $out) | Should -BeExactly 'processors=4'
    }

    It 'throws when a *user-data* template does not start with #cloud-config' {
        $in  = Join-Path $script:tmp 'x.user-data.template'
        $out = Join-Path $script:tmp 'x.user-data'
        Set-Content -Path $in -Value 'not a cloud config' -NoNewline
        { Expand-KitTemplate -Path $in -OutPath $out -Replacements @{} } | Should -Throw '*#cloud-config*'
    }

    It 'accepts a *user-data* template that starts with #cloud-config' {
        $in  = Join-Path $script:tmp 'x.user-data.template'
        $out = Join-Path $script:tmp 'x.user-data'
        Set-Content -Path $in -Value "#cloud-config`nfoo: bar" -NoNewline
        { Expand-KitTemplate -Path $in -OutPath $out -Replacements @{} } | Should -Not -Throw
    }

    It 'does not enforce #cloud-config on non user-data files' {
        $in  = Join-Path $script:tmp 'wsl.config.template'
        $out = Join-Path $script:tmp '.wslconfig'
        Set-Content -Path $in -Value '[wsl2]' -NoNewline
        { Expand-KitTemplate -Path $in -OutPath $out -Replacements @{} } | Should -Not -Throw
    }

    It 'writes UTF-8 without a BOM' {
        $in  = Join-Path $script:tmp 'in.txt'
        $out = Join-Path $script:tmp 'out.txt'
        Set-Content -Path $in -Value 'abc' -NoNewline
        Expand-KitTemplate -Path $in -OutPath $out -Replacements @{}
        $bytes = [System.IO.File]::ReadAllBytes($out)
        ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) | Should -BeFalse
    }

    It 'throws for a missing template' {
        { Expand-KitTemplate -Path (Join-Path $script:tmp 'nope.txt') -OutPath (Join-Path $script:tmp 'o') -Replacements @{} } |
            Should -Throw '*not found*'
    }
}

Describe 'render-templates.ps1 (integration)' {
    BeforeAll {
        $script:secretsPath = Join-Path $script:RepoRoot 'config/secrets.local.ps1'
        $script:backupPath  = "$script:secretsPath.bak-test"
        $script:backedUp    = $false
        $script:created     = $false

        if (Test-Path $script:secretsPath) {
            Copy-Item $script:secretsPath $script:backupPath -Force
            $script:backedUp = $true
        }
        @'
$LinuxPassword = "TestP@ss123"
$GitUserName   = "Test User"
$GitUserEmail  = "test@example.com"
$SshKeyComment = "test@example.com"
'@ | Set-Content -Path $script:secretsPath
        $script:created = $true

        & (Join-Path $script:ScriptsDir 'render-templates.ps1') | Out-Null
        $renderDir = Join-Path $script:RepoRoot '.cloud-init-rendered'
        $script:cloudInit = Get-Content -Raw (Join-Path $renderDir 'Ubuntu-DevOps.user-data')
        $script:wslConfig = Get-Content -Raw (Join-Path $renderDir '.wslconfig')
    }
    AfterAll {
        if ($script:backedUp) {
            Copy-Item $script:backupPath $script:secretsPath -Force
            Remove-Item $script:backupPath -Force
        } elseif ($script:created) {
            Remove-Item $script:secretsPath -Force
        }
    }

    It 'leaves no {{placeholders}} in the rendered cloud-init' {
        $script:cloudInit | Should -Not -Match '\{\{.*\}\}'
    }
    It 'renders cloud-init starting with #cloud-config' {
        $script:cloudInit.StartsWith('#cloud-config') | Should -BeTrue
    }
    It 'substitutes identity and the pinned tool version' {
        $script:cloudInit | Should -Match 'name: devops'
        $script:cloudInit | Should -Match 'gitlabber==2\.1\.1'
    }
    It 'substitutes the WSL memory in .wslconfig' {
        $script:wslConfig | Should -Match 'memory=8GB'
    }
    It 'creates the docker group before usermod (avoids "group does not exist")' {
        $script:cloudInit | Should -Match 'groupadd -f docker'
        $gi = $script:cloudInit.IndexOf('groupadd -f docker')
        $ui = $script:cloudInit.IndexOf('usermod -aG docker')
        $gi | Should -BeGreaterThan -1
        $gi | Should -BeLessThan $ui
    }
}
