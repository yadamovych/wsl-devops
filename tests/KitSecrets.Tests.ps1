#Requires -Version 5.1
# Pester v5 tests for secrets + prerequisite helpers. Cross-platform (no WSL needed).

BeforeAll {
    $script:RepoRoot   = Split-Path -Parent $PSScriptRoot
    $script:ScriptsDir = Join-Path $script:RepoRoot 'scripts'
    Import-Module (Join-Path $script:ScriptsDir 'KitSecrets.psm1') -Force

    function Read-KitSecretFile {
        param([string]$Path)
        & {
            param($p)
            . $p
            [pscustomobject]@{
                LinuxPassword = $LinuxPassword
                GitUserName   = $GitUserName
                GitUserEmail  = $GitUserEmail
                SshKeyComment = $SshKeyComment
            }
        } $Path
    }
}

Describe 'New-KitSecrets' {
    BeforeEach {
        $script:tmp  = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $script:tmp | Out-Null
        $script:file = Join-Path $script:tmp 'secrets.local.ps1'
    }
    AfterEach {
        if (Test-Path $script:tmp) { Remove-Item -Recurse -Force $script:tmp }
    }

    It 'writes a dot-sourceable file with the supplied values' {
        New-KitSecrets -Path $script:file -LinuxPassword 'P@ss123' -GitUserName 'Jane Doe' -GitUserEmail 'jane@example.com' -SshKeyComment 'laptop'
        $v = Read-KitSecretFile -Path $script:file
        $v.LinuxPassword | Should -BeExactly 'P@ss123'
        $v.GitUserName   | Should -BeExactly 'Jane Doe'
        $v.GitUserEmail  | Should -BeExactly 'jane@example.com'
        $v.SshKeyComment | Should -BeExactly 'laptop'
    }

    It 'safely escapes special characters in the password' {
        $pw = "a'b`"c`$d e"
        New-KitSecrets -Path $script:file -LinuxPassword $pw -GitUserName 'N' -GitUserEmail 'e@x.io'
        (Read-KitSecretFile -Path $script:file).LinuxPassword | Should -BeExactly $pw
    }

    It 'defaults SshKeyComment to the git email' {
        New-KitSecrets -Path $script:file -LinuxPassword 'P@ss123' -GitUserName 'N' -GitUserEmail 'e@x.io'
        (Read-KitSecretFile -Path $script:file).SshKeyComment | Should -BeExactly 'e@x.io'
    }

    It 'rejects an empty password' {
        { New-KitSecrets -Path $script:file -LinuxPassword '   ' -GitUserName 'N' -GitUserEmail 'e@x.io' } |
            Should -Throw '*must be a real value*'
    }

    It 'rejects the CHANGE_ME placeholder' {
        { New-KitSecrets -Path $script:file -LinuxPassword 'CHANGE_ME' -GitUserName 'N' -GitUserEmail 'e@x.io' } |
            Should -Throw '*CHANGE_ME*'
    }

    It 'will not overwrite an existing file without -Force' {
        New-KitSecrets -Path $script:file -LinuxPassword 'P@ss123' -GitUserName 'N' -GitUserEmail 'e@x.io'
        { New-KitSecrets -Path $script:file -LinuxPassword 'Other1' -GitUserName 'N' -GitUserEmail 'e@x.io' } |
            Should -Throw '*already exists*'
    }

    It 'overwrites with -Force' {
        New-KitSecrets -Path $script:file -LinuxPassword 'P@ss123' -GitUserName 'N' -GitUserEmail 'e@x.io'
        New-KitSecrets -Path $script:file -LinuxPassword 'Other1' -GitUserName 'N' -GitUserEmail 'e@x.io' -Force
        (Read-KitSecretFile -Path $script:file).LinuxPassword | Should -BeExactly 'Other1'
    }
}

Describe 'Get-KitSecretsStatus' {
    BeforeEach {
        $script:tmp  = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $script:tmp | Out-Null
        $script:file = Join-Path $script:tmp 'secrets.local.ps1'
    }
    AfterEach {
        if (Test-Path $script:tmp) { Remove-Item -Recurse -Force $script:tmp }
    }

    It 'reports a missing file as not existing / invalid' {
        $st = Get-KitSecretsStatus -Path $script:file
        $st.Exists  | Should -BeFalse
        $st.IsValid | Should -BeFalse
    }

    It 'reports CHANGE_ME as a placeholder and invalid' {
        Set-Content -Path $script:file -Value '$LinuxPassword = "CHANGE_ME"'
        $st = Get-KitSecretsStatus -Path $script:file
        $st.Exists        | Should -BeTrue
        $st.IsPlaceholder | Should -BeTrue
        $st.IsValid       | Should -BeFalse
    }

    It 'reports a real password as valid' {
        New-KitSecrets -Path $script:file -LinuxPassword 'P@ss123' -GitUserName 'N' -GitUserEmail 'e@x.io'
        (Get-KitSecretsStatus -Path $script:file).IsValid | Should -BeTrue
    }
}

Describe 'Test-KitInteractive' {
    It 'returns false when KIT_NONINTERACTIVE=1' {
        $env:KIT_NONINTERACTIVE = '1'
        try { Test-KitInteractive | Should -BeFalse }
        finally { Remove-Item Env:KIT_NONINTERACTIVE -ErrorAction SilentlyContinue }
    }
}

Describe 'Get-KitPrerequisite' {
    It 'includes a required WSL check (absent on non-Windows)' {
        $checks = Get-KitPrerequisite
        $wsl = $checks | Where-Object Name -eq 'WSL (wsl command)'
        $wsl           | Should -Not -BeNullOrEmpty
        $wsl.Required  | Should -BeTrue
    }

    It 'reports PowerShell version as satisfied' {
        $ps = Get-KitPrerequisite | Where-Object Name -like 'PowerShell*'
        $ps.Ok | Should -BeTrue
    }

    It 'reflects secrets validity when given a path' {
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $tmp | Out-Null
        try {
            $f = Join-Path $tmp 'secrets.local.ps1'
            New-KitSecrets -Path $f -LinuxPassword 'P@ss123' -GitUserName 'N' -GitUserEmail 'e@x.io'
            $secret = Get-KitPrerequisite -SecretsPath $f | Where-Object Name -like '*secrets*'
            $secret.Ok | Should -BeTrue
        } finally {
            Remove-Item -Recurse -Force $tmp
        }
    }
}

Describe 'Get-KitPrerequisite (mocked Windows host scenarios)' {
    It 'passes every required check on a fully-ready Windows host' {
        Mock -ModuleName KitSecrets -CommandName Get-KitOsInfo               -MockWith { [pscustomobject]@{ IsWindows = $true; Caption = 'Windows 11 Pro'; Build = 22631 } }
        Mock -ModuleName KitSecrets -CommandName Test-KitVirtualizationEnabled -MockWith { $true }
        Mock -ModuleName KitSecrets -CommandName Get-KitWslInfo              -MockWith { [pscustomobject]@{ Installed = $true; HasVersionCommand = $true } }
        Mock -ModuleName KitSecrets -CommandName Test-KitDockerReady         -MockWith { $true }
        Mock -ModuleName KitSecrets -CommandName Test-KitCommand             -MockWith { $true }
        Mock -ModuleName KitSecrets -CommandName Get-KitGitCredentialHelperPath -MockWith {
            'C:\Program Files\Git\mingw64\libexec\git-core\git-credential-wincred.exe'
        }

        $checks  = Get-KitPrerequisite
        $missing = @($checks | Where-Object { $_.Required -and -not $_.Ok })
        $missing.Count | Should -Be 0
        ($checks | Where-Object Name -like 'Docker*').Ok | Should -BeTrue
    }

    It 'flags a disabled BIOS virtualization as a required failure' {
        Mock -ModuleName KitSecrets -CommandName Get-KitOsInfo               -MockWith { [pscustomobject]@{ IsWindows = $true; Caption = 'Windows 11 Pro'; Build = 22631 } }
        Mock -ModuleName KitSecrets -CommandName Test-KitVirtualizationEnabled -MockWith { $false }
        Mock -ModuleName KitSecrets -CommandName Get-KitWslInfo              -MockWith { [pscustomobject]@{ Installed = $true; HasVersionCommand = $true } }
        Mock -ModuleName KitSecrets -CommandName Test-KitDockerReady         -MockWith { $true }
        Mock -ModuleName KitSecrets -CommandName Test-KitCommand             -MockWith { $true }
        Mock -ModuleName KitSecrets -CommandName Get-KitGitCredentialHelperPath -MockWith {
            'C:\Program Files\Git\mingw64\libexec\git-core\git-credential-wincred.exe'
        }

        $vt = Get-KitPrerequisite | Where-Object Name -like 'Hardware virtualization*'
        $vt.Required | Should -BeTrue
        $vt.Ok       | Should -BeFalse
    }

    It 'reports Docker Desktop / Windows Terminal as non-blocking warnings on a fresh host' {
        Mock -ModuleName KitSecrets -CommandName Get-KitOsInfo               -MockWith { [pscustomobject]@{ IsWindows = $true; Caption = 'Windows 11 Pro'; Build = 22631 } }
        Mock -ModuleName KitSecrets -CommandName Test-KitVirtualizationEnabled -MockWith { $true }
        Mock -ModuleName KitSecrets -CommandName Get-KitWslInfo              -MockWith { [pscustomobject]@{ Installed = $true; HasVersionCommand = $true } }
        Mock -ModuleName KitSecrets -CommandName Test-KitDockerReady         -MockWith { $false }
        Mock -ModuleName KitSecrets -CommandName Test-KitCommand -ParameterFilter { $Name -eq 'git' } -MockWith { $true }
        Mock -ModuleName KitSecrets -CommandName Test-KitCommand -ParameterFilter { $Name -eq 'wt' }  -MockWith { $false }
        Mock -ModuleName KitSecrets -CommandName Get-KitGitCredentialHelperPath -MockWith {
            'C:\Program Files\Git\mingw64\libexec\git-core\git-credential-wincred.exe'
        }

        $checks  = Get-KitPrerequisite
        $docker  = $checks | Where-Object Name -like 'Docker*'
        $wt      = $checks | Where-Object Name -like 'Windows Terminal*'
        $docker.Required | Should -BeFalse
        $docker.Ok       | Should -BeFalse
        $wt.Required     | Should -BeFalse
        # Docker/WT being absent must not produce a required failure.
        @($checks | Where-Object { $_.Required -and -not $_.Ok }).Count | Should -Be 0
    }

    It 'fails when git is on PATH but the WSL credential helper is missing' {
        Mock -ModuleName KitSecrets -CommandName Get-KitOsInfo -MockWith {
            [pscustomobject]@{ IsWindows = $true; Caption = 'Windows 11 Pro'; Build = 22631 }
        }
        Mock -ModuleName KitSecrets -CommandName Test-KitVirtualizationEnabled -MockWith { $true }
        Mock -ModuleName KitSecrets -CommandName Get-KitWslInfo -MockWith {
            [pscustomobject]@{ Installed = $true; HasVersionCommand = $true }
        }
        Mock -ModuleName KitSecrets -CommandName Test-KitDockerReady -MockWith { $true }
        Mock -ModuleName KitSecrets -CommandName Test-KitCommand -MockWith { $true }
        Mock -ModuleName KitSecrets -CommandName Get-KitGitCredentialHelperPath -MockWith { $null }

        $git = Get-KitPrerequisite | Where-Object Name -like 'Git for Windows*'
        $git.Required | Should -BeTrue
        $git.Ok       | Should -BeFalse
        $git.Detail   | Should -Match 'git-credential-wincred'
    }

    It 'fails the Windows OS check when not running on Windows' {
        Mock -ModuleName KitSecrets -CommandName Get-KitOsInfo -MockWith { [pscustomobject]@{ IsWindows = $false; Caption = $null; Build = $null } }
        $osCheck = Get-KitPrerequisite | Where-Object Name -eq 'Operating system: Windows'
        $osCheck.Required | Should -BeTrue
        $osCheck.Ok       | Should -BeFalse
    }
}

Describe 'Request-KitSecrets (interactive flow, mocked prompts)' {
    BeforeEach {
        $script:tmp  = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $script:tmp | Out-Null
        $script:file = Join-Path $script:tmp 'secrets.local.ps1'
    }
    AfterEach {
        if (Test-Path $script:tmp) { Remove-Item -Recurse -Force $script:tmp }
    }

    It 'prompts the user and writes a valid secrets file' {
        Mock -ModuleName KitSecrets -CommandName Test-KitInteractive -MockWith { $true }
        Mock -ModuleName KitSecrets -CommandName Read-Host -MockWith {
            param([string]$Prompt, [switch]$AsSecureString)
            if ($AsSecureString) {
                $ss = New-Object System.Security.SecureString
                foreach ($ch in 'MyS3cretP@ss!'.ToCharArray()) { $ss.AppendChar($ch) }
                return $ss
            }
            switch -Wildcard ($Prompt) {
                '*user.name*'  { 'Jane Developer' }
                '*user.email*' { 'jane@example.com' }
                '*SSH key*'    { '' }            # accept the default (email)
                default        { '' }
            }
        }

        Request-KitSecrets -Path $script:file

        $v = Read-KitSecretFile -Path $script:file
        $v.LinuxPassword | Should -BeExactly 'MyS3cretP@ss!'
        $v.GitUserName   | Should -BeExactly 'Jane Developer'
        $v.GitUserEmail  | Should -BeExactly 'jane@example.com'
        $v.SshKeyComment | Should -BeExactly 'jane@example.com'
    }
}

Describe 'render-templates.ps1 secrets fallback (non-interactive)' {
    BeforeAll {
        $env:KIT_NONINTERACTIVE = '1'
        $script:secretsPath = Join-Path $script:RepoRoot 'config/secrets.local.ps1'
        $script:backupPath  = "$script:secretsPath.bak-test"
        $script:backedUp    = $false
        if (Test-Path $script:secretsPath) {
            Move-Item $script:secretsPath $script:backupPath -Force
            $script:backedUp = $true
        }
    }
    AfterAll {
        if ($script:backedUp) { Move-Item $script:backupPath $script:secretsPath -Force }
        Remove-Item Env:KIT_NONINTERACTIVE -ErrorAction SilentlyContinue
    }

    It 'throws actionable guidance pointing to new-secrets.ps1' {
        { & (Join-Path $script:ScriptsDir 'render-templates.ps1') } | Should -Throw '*new-secrets*'
    }
}
