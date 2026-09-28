BeforeAll {
    $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $manifestPath = Join-Path $repositoryRoot 'PSHomebridge/Output/PSHomebridge/1.0.0/PSHomebridge.psd1'
    Remove-Module PSHomebridge -Force -ErrorAction SilentlyContinue
    Import-Module $manifestPath -Force
}

Describe 'Homebridge status resources' {
    It 'maps every supported status type to its documented route' {
        $cases = [ordered]@{
            ChildBridge           = '/api/status/homebridge/child-bridges'
            Cpu                   = '/api/status/cpu'
            Homebridge            = '/api/status/homebridge'
            HomebridgeVersion     = '/api/status/homebridge-version'
            Memory                = '/api/status/ram'
            Network               = '/api/status/network'
            NodeJs                = '/api/status/nodejs'
            RaspberryPiThrottling = '/api/status/rpi/throttled'
            ServerInformation     = '/api/status/server-information'
            Uptime                = '/api/status/uptime'
        }

        InModuleScope PSHomebridge -Parameters @{ Cases = $cases } {
            param($Cases)

            Mock Invoke-HomebridgeApiRequest { [pscustomobject]@{ marker = $Path } }

            foreach ($case in $Cases.GetEnumerator()) {
                $result = Get-HomebridgeStatus -InstanceName home -Type $case.Key

                $result.marker | Should -Be $case.Value
                $result.PSTypeNames[0] | Should -Be "PSHomebridge.Status.$($case.Key)"
            }
        }
    }

    It 'reports a concise error when Raspberry Pi status is unavailable' {
        InModuleScope PSHomebridge {
            Mock Invoke-HomebridgeApiRequest {
                throw 'This command is only available on Raspberry Pi'
            }

            { Get-HomebridgeStatus -InstanceName home -Type RaspberryPiThrottling -ErrorAction Stop } |
                Should -Throw -ErrorId 'HomebridgeStatusUnsupportedPlatform,Get-HomebridgeStatus'
        }
    }
}

Describe 'Homebridge accessory resources' {
    It 'gets all accessories or one escaped accessory identifier' {
        InModuleScope PSHomebridge {
            Mock Invoke-HomebridgeApiRequest { [pscustomobject]@{ marker = $Path } }

            $all = Get-HomebridgeAccessory -InstanceName home
            $single = Get-HomebridgeAccessory -InstanceName home -UniqueId 'one/two'

            $all.marker | Should -Be '/api/accessories'
            $single.marker | Should -Be '/api/accessories/one%2Ftwo'
            $single.PSTypeNames[0] | Should -Be 'PSHomebridge.Accessory'
        }
    }

    It 'gets the accessory layout' {
        InModuleScope PSHomebridge {
            Mock Invoke-HomebridgeApiRequest { [pscustomobject]@{ marker = $Path } }

            $result = Get-HomebridgeAccessoryLayout -InstanceName home

            $result.marker | Should -Be '/api/accessories/layout'
            $result.PSTypeNames[0] | Should -Be 'PSHomebridge.AccessoryLayout'
        }
    }
}

Describe 'Homebridge server diagnostic resources' {
    It 'maps every supported diagnostic type to its documented route' {
        $cases = [ordered]@{
            AccessoryOverview      = '/api/server/accessory-overview'
            BridgeNetworkInterface = '/api/server/network-interfaces/bridge'
            CachedAccessory        = '/api/server/cached-accessories'
            MatterAccessory        = '/api/server/matter-accessories'
            MdnsAdvertiser         = '/api/server/mdns-advertiser'
            NetworkOverview        = '/api/server/network/overview'
            Pairing                = '/api/server/pairing'
            PairingList            = '/api/server/pairings'
            Port                   = '/api/server/port'
            PortRange              = '/api/server/ports'
            SystemNetworkInterface = '/api/server/network-interfaces/system'
        }

        InModuleScope PSHomebridge -Parameters @{ Cases = $cases } {
            param($Cases)

            Mock Invoke-HomebridgeApiRequest { [pscustomobject]@{ marker = $Path } }

            foreach ($case in $Cases.GetEnumerator()) {
                $result = Get-HomebridgeServerDiagnostic -InstanceName home -Type $case.Key

                $result.marker | Should -Be $case.Value
                $result.PSTypeNames[0] | Should -Be "PSHomebridge.ServerDiagnostic.$($case.Key)"
            }
        }
    }
}

Describe 'Homebridge plugin metadata resources' {
    It 'maps every supported metadata type to its documented route' {
        $cases = [ordered]@{
            Alias            = '/api/plugins/alias/homebridge-example'
            AvailableVersion = '/api/plugins/lookup/homebridge-example/versions'
            Changelog        = '/api/plugins/changelog/homebridge-example'
            EditorContext    = '/api/plugins/homebridge-example/editor-context'
            Registry         = '/api/plugins/lookup/homebridge-example'
            Release          = '/api/plugins/release/homebridge-example'
            Schema           = '/api/plugins/config-schema/homebridge-example'
        }

        InModuleScope PSHomebridge -Parameters @{ Cases = $cases } {
            param($Cases)

            Mock Invoke-HomebridgeApiRequest { [pscustomobject]@{ marker = $Path } }

            foreach ($case in $Cases.GetEnumerator()) {
                $result = Get-HomebridgePluginInformation -InstanceName home -PluginName homebridge-example -Type $case.Key

                $result.marker | Should -Be $case.Value
                $result.PSTypeNames[0] | Should -Be "PSHomebridge.PluginInformation.$($case.Key)"
            }
        }
    }

    It 'passes a release version as a query value' {
        InModuleScope PSHomebridge {
            Mock Invoke-HomebridgeApiRequest { [pscustomobject]@{ marker = $Query.version } }

            $result = Get-HomebridgePluginInformation -InstanceName home -PluginName homebridge-example -Type Release -ReleaseVersion beta

            $result.marker | Should -Be 'beta'
        }
    }

    It 'searches the plugin registry with escaped search text' {
        InModuleScope PSHomebridge {
            Mock Invoke-HomebridgeApiRequest { [pscustomobject]@{ marker = $Path } }

            $result = Find-HomebridgePlugin -InstanceName home -Query 'camera plugin'

            $result.marker | Should -Be '/api/plugins/search/camera%20plugin'
            $result.PSTypeNames[0] | Should -Be 'PSHomebridge.PluginSearchResult'
        }
    }
}

Describe 'Homebridge backup management resources' {
    It 'creates a backup through the documented route' {
        InModuleScope PSHomebridge {
            Mock Invoke-HomebridgeApiRequest { [pscustomobject]@{ marker = $Path } }

            $result = New-HomebridgeBackup -InstanceName home -Confirm:$false

            $result.marker | Should -Be '/api/backup'
            $result.PSTypeNames[0] | Should -Be 'PSHomebridge.Backup'
            Should -Invoke Invoke-HomebridgeApiRequest -ParameterFilter { $Method -eq 'POST' -and $Confirm -eq $false }
        }
    }

    It 'removes a scheduled backup through an escaped route' {
        InModuleScope PSHomebridge {
            Mock Invoke-HomebridgeApiRequest

            Remove-HomebridgeBackup -InstanceName home -BackupId 'one/two' -Confirm:$false

            Should -Invoke Invoke-HomebridgeApiRequest -ParameterFilter {
                $Method -eq 'DELETE' -and
                $Path -eq '/api/backup/scheduled-backups/one%2Ftwo' -and
                $Confirm -eq $false
            }
        }
    }

    It 'downloads a current instance backup when BackupId is omitted' {
        InModuleScope PSHomebridge -Parameters @{ Destination = (Join-Path $TestDrive 'current.tar.gz') } {
            param($Destination)

            Mock Invoke-HomebridgeApiRequest {
                Set-Content -LiteralPath $OutFile -Value 'backup-content'
            }

            $result = Save-HomebridgeBackup -InstanceName home -OutFile $Destination -Confirm:$false

            $result.FullName | Should -Be $Destination
            Should -Invoke Invoke-HomebridgeApiRequest -ParameterFilter {
                $Method -eq 'GET' -and
                $Path -eq '/api/backup/download'
            }
        }
    }
}
