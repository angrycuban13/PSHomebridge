Describe 'PSHomebridge module' {
    BeforeAll {
        $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $script:manifestPath = Join-Path $repositoryRoot 'PSHomebridge/Output/PSHomebridge/1.0.0/PSHomebridge.psd1'
        Remove-Module PSHomebridge -Force -ErrorAction SilentlyContinue
        Import-Module $script:manifestPath -Force
    }

    It 'exports only the approved public commands' {
        $expected = @(
            'Find-HomebridgePlugin'
            'Get-HomebridgeAccessory'
            'Get-HomebridgeAccessoryLayout'
            'Get-HomebridgeBackup'
            'Get-PSHomebridgeConnection'
            'Get-HomebridgePlugin'
            'Get-HomebridgePluginInformation'
            'Get-HomebridgeServerDiagnostic'
            'Get-HomebridgeStatus'
            'Invoke-HomebridgeApiRequest'
            'New-HomebridgeBackup'
            'Remove-HomebridgeBackup'
            'Remove-PSHomebridgeConnection'
            'Save-HomebridgeBackup'
            'Set-PSHomebridgeConnection'
        )
        @(Get-Command -Module PSHomebridge).Name | Sort-Object | Should -Be ($expected | Sort-Object)
    }

    It 'targets PowerShell 7 or later' {
        [version](Import-PowerShellDataFile $script:manifestPath).PowerShellVersion | Should -BeGreaterOrEqual ([version]'7.0')
    }

    It 'uses InstanceName for every public saved-connection selector' {
        foreach ($command in @(Get-Command -Module PSHomebridge)) {
            $command.Parameters.ContainsKey('Name') | Should -BeFalse -Because "$($command.Name) must not expose an ambiguous Name parameter"
        }
    }

    It 'uses readable labels in default format views' {
        $formatPath = Join-Path (Split-Path $script:manifestPath) 'PSHomebridge.Format.ps1xml'
        [xml] $formatData = Get-Content -LiteralPath $formatPath -Raw
        $labels = @($formatData.Configuration.ViewDefinitions.View.TableControl.TableHeaders.TableColumnHeader.Label)

        $labels | Should -Contain 'Instance Name'
        $labels | Should -Contain 'Installed Version'
        $labels | Should -Contain 'CPU Temperature'
        $labels | Should -Contain 'Unique ID'
        $labels | Should -Not -Contain 'instanceName'
        $labels | Should -Not -Contain 'installedVersion'
    }
}

Describe 'PSHomebridge consumer wrappers' {
    BeforeAll {
        if (-not (Get-Module PSHomebridge)) {
            $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            Import-Module (Join-Path $repositoryRoot 'PSHomebridge/Output/PSHomebridge/1.0.0/PSHomebridge.psd1') -Force
        }
        InModuleScope PSHomebridge {
            Mock Invoke-HomebridgeApiRequest {
                if ($Path -eq '/api/plugins') {
                    return @(
                        [pscustomobject]@{ name = 'a'; updateAvailable = $true; custom = 1 }
                        [pscustomobject]@{ name = 'b'; updateAvailable = $false; custom = 2 }
                    )
                }

                if ($Path -eq '/api/status/homebridge-version') {
                    return [pscustomobject]@{
                        installedVersion = '1'
                        latestVersion    = '2'
                        updateAvailable  = $true
                        custom           = 3
                    }
                }

                if ($Path -eq '/api/backup/scheduled-backups') {
                    return @(
                        [pscustomobject]@{ id = 'one'; fileName = 'one.tar.gz'; custom = 4 }
                    )
                }
            }
        }
    }

    It 'preserves plugin objects while filtering updates' {
        InModuleScope PSHomebridge {
            $result = @(Get-HomebridgePlugin -InstanceName home -UpdateAvailable)
            $result.Count | Should -Be 1
            $result[0].custom | Should -Be 1
            $result[0].PSTypeNames[0] | Should -Be 'PSHomebridge.Plugin'
        }
    }

    It 'preserves version status properties' {
        InModuleScope PSHomebridge {
            $result = Get-HomebridgeStatus -InstanceName home -Type HomebridgeVersion
            $result.custom | Should -Be 3
            $result.PSTypeNames[0] | Should -Be 'PSHomebridge.Status.HomebridgeVersion'
        }
    }

    It 'preserves backup properties' {
        InModuleScope PSHomebridge {
            $result = @(Get-HomebridgeBackup -InstanceName home)
            $result[0].custom | Should -Be 4
            $result[0].PSTypeNames[0] | Should -Be 'PSHomebridge.Backup'
        }
    }
}
