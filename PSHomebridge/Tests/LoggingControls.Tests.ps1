BeforeDiscovery {
    Import-Module "$PSScriptRoot/../Output/PSHomebridge/1.0.0/PSHomebridge.psd1" -Force
}

Describe 'Process logging controls' {
    InModuleScope PSHomebridge {
        BeforeEach {
            $previousDisabled = $env:PSHOMEBRIDGE_LOG_DISABLED
            $previousDirectory = $env:PSHOMEBRIDGE_LOG_DIRECTORY
            $env:PSHOMEBRIDGE_LOG_DISABLED = $null
            $env:PSHOMEBRIDGE_LOG_DIRECTORY = $null
            Mock Invoke-RestMethod {
                if ($Uri -like '*/api/auth/noauth') { return [pscustomobject]@{ access_token = 'fixture-token' } }
                throw 'fixture failure'
            }
            Mock Write-PSHomebridgeLogEntry
            $requestParameters = @{
                Url              = 'http://localhost:8581'
                NoAuthentication = $true
                Method           = 'GET'
                Path             = '/api/status/homebridge-version'
            }
        }

        AfterEach {
            $env:PSHOMEBRIDGE_LOG_DISABLED = $previousDisabled
            $env:PSHOMEBRIDGE_LOG_DIRECTORY = $previousDirectory
        }

        It 'disables logging without suppressing the original error' {
            $env:PSHOMEBRIDGE_LOG_DISABLED = '1'

            { Invoke-HomebridgeApiRequest @requestParameters -ErrorAction Stop } | Should -Throw '*fixture failure*'
            Should -Invoke Write-PSHomebridgeLogEntry -Times 0
        }

        It 'uses the requested log directory' {
            $env:PSHOMEBRIDGE_LOG_DIRECTORY = $TestDrive
            $expectedDirectory = $TestDrive

            Invoke-HomebridgeApiRequest @requestParameters -ErrorAction SilentlyContinue

            Should -Invoke Write-PSHomebridgeLogEntry -Times 1 -Exactly -ParameterFilter {
                $LogFileDirectory -eq $expectedDirectory
            }
        }

        It 'keeps logging enabled unless disabled is exactly 1' {
            $env:PSHOMEBRIDGE_LOG_DISABLED = '0'

            Invoke-HomebridgeApiRequest @requestParameters -ErrorAction SilentlyContinue

            Should -Invoke Write-PSHomebridgeLogEntry -Times 1 -Exactly
        }

        It 'uses the default directory when the override is whitespace' {
            $env:PSHOMEBRIDGE_LOG_DIRECTORY = '   '

            Invoke-HomebridgeApiRequest @requestParameters -ErrorAction SilentlyContinue

            Should -Invoke Write-PSHomebridgeLogEntry -Times 1 -Exactly -ParameterFilter {
                [System.String]::IsNullOrEmpty($LogFileDirectory)
            }
        }

        It 'applies changes on the next failure without reimporting the module' {
            $env:PSHOMEBRIDGE_LOG_DISABLED = '1'
            Invoke-HomebridgeApiRequest @requestParameters -ErrorAction SilentlyContinue

            $env:PSHOMEBRIDGE_LOG_DISABLED = $null
            Invoke-HomebridgeApiRequest @requestParameters -ErrorAction SilentlyContinue

            Should -Invoke Write-PSHomebridgeLogEntry -Times 1 -Exactly
        }

        It 'preserves the original failure when logging throws' {
            Mock Write-PSHomebridgeLogEntry { throw 'logger failure' }

            {
                Invoke-HomebridgeApiRequest @requestParameters -ErrorAction Stop -WarningAction SilentlyContinue
            } | Should -Throw '*fixture failure*'
        }
    }
}

Describe 'Write-PSHomebridgeLogEntry' {
    InModuleScope PSHomebridge {
        It 'writes a plain-text log with an explicit portable path' {
            $logDirectory = Join-Path $TestDrive 'logs'
            $logParameters = @{
                Message          = 'portable test'
                LogFileDirectory = $logDirectory
                LogFileName      = 'PSHomebridge.log'
                NoConsoleOutput  = $true
            }
            Write-PSHomebridgeLogEntry @logParameters
            $logPath = Join-Path $logDirectory 'PSHomebridge.log'
            Test-Path -LiteralPath $logPath | Should -BeTrue
            Get-Content -Raw -LiteralPath $logPath | Should -Match 'portable test'
        }
    }
}
