Describe 'PSHomebridge module' {
    BeforeAll {
        $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $script:manifestPath = Join-Path $repositoryRoot 'PSHomebridge/Source/PSHomebridge.psd1'
        Remove-Module PSHomebridge -Force -ErrorAction SilentlyContinue
        Import-Module $script:manifestPath -Force
    }

    It 'exports only the approved public commands' {
        $expected = @(
            'Get-HomebridgeBackup'
            'Get-HomebridgeConnection'
            'Get-HomebridgePlugin'
            'Get-HomebridgeStatus'
            'Invoke-HomebridgeApiRequest'
            'New-HomebridgeConnection'
            'Save-HomebridgeBackup'
            'Remove-HomebridgeConnection'
            'Set-HomebridgeConnection'
        )
        @(Get-Command -Module PSHomebridge).Name | Sort-Object | Should -Be ($expected | Sort-Object)
    }

    It 'targets PowerShell 7 or later' {
        [version](Import-PowerShellDataFile $script:manifestPath).PowerShellVersion | Should -BeGreaterOrEqual ([version]'7.0')
    }
}

Describe 'PSHomebridge consumer wrappers' {
    BeforeAll {
        if (-not (Get-Module PSHomebridge)) {
            $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            Import-Module (Join-Path $repositoryRoot 'PSHomebridge/Source/PSHomebridge.psd1') -Force
        }
        InModuleScope PSHomebridge {
            Mock Invoke-HomebridgeApiRequest {
                if ($Path -eq '/api/plugins') { return @([pscustomobject]@{ name = 'a'; updateAvailable = $true; custom = 1 }, [pscustomobject]@{ name = 'b'; updateAvailable = $false; custom = 2 }) }
                if ($Path -eq '/api/status/homebridge-version') { return [pscustomobject]@{ installedVersion = '1'; latestVersion = '2'; updateAvailable = $true; custom = 3 } }
                if ($Path -eq '/api/backup/scheduled-backups') { return @([pscustomobject]@{ id = 'one'; fileName = 'one.tar.gz'; custom = 4 }) }
            }
        }
    }

    It 'preserves plugin objects while filtering updates' {
        InModuleScope PSHomebridge {
            $result = @(Get-HomebridgePlugin -Name home -UpdateAvailable)
            $result.Count | Should -Be 1
            $result[0].custom | Should -Be 1
            $result[0].PSTypeNames[0] | Should -Be 'PSHomebridge.Plugin'
        }
    }

    It 'preserves version status properties' {
        InModuleScope PSHomebridge {
            $result = Get-HomebridgeStatus -Name home -Type HomebridgeVersion
            $result.custom | Should -Be 3
            $result.PSTypeNames[0] | Should -Be 'PSHomebridge.Status.HomebridgeVersion'
        }
    }

    It 'preserves backup properties' {
        InModuleScope PSHomebridge {
            $result = @(Get-HomebridgeBackup -Name home)
            $result[0].custom | Should -Be 4
            $result[0].PSTypeNames[0] | Should -Be 'PSHomebridge.Backup'
        }
    }
}
