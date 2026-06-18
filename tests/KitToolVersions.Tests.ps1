#Requires -Version 5.1
# Pester v5 tests for KitToolVersions.psm1 (no network calls).

BeforeAll {
    $script:ScriptsDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts'
    Import-Module (Join-Path $script:ScriptsDir 'KitToolVersions.psm1') -Force
}

Describe 'Normalize-VersionString' {
    It 'strips a leading v' {
        Normalize-VersionString -Version 'v1.32.0' | Should -Be '1.32.0'
    }
    It 'trims whitespace' {
        Normalize-VersionString -Version ' 1.2.3 ' | Should -Be '1.2.3'
    }
}

Describe 'Compare-PinnedVersion' {
    It 'reports pinned older than latest' {
        Compare-PinnedVersion -Pinned '1.0.0' -Latest '2.0.0' | Should -Be -1
    }
    It 'reports equal versions' {
        Compare-PinnedVersion -Pinned 'v3.17.3' -Latest '3.17.3' | Should -Be 0
    }
    It 'reports pinned ahead of latest' {
        Compare-PinnedVersion -Pinned '2.0.0' -Latest '1.9.9' | Should -Be 1
    }
}
