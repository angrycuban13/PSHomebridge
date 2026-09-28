BeforeAll {
    $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $manifestPath = Join-Path $repositoryRoot 'PSHomebridge/Output/PSHomebridge/1.0.0/PSHomebridge.psd1'
    Remove-Module PSHomebridge -Force -ErrorAction SilentlyContinue
    Import-Module $manifestPath -Force
}

Describe 'Homebridge authentication and transport' {
    It 'uses the login endpoint and bearer token' {
        InModuleScope PSHomebridge {
            $secure = ConvertTo-SecureString 'secret-password' -AsPlainText -Force
            $credential = [pscredential]::new('admin', $secure)
            Mock Invoke-RestMethod {
                if ($Uri -like '*/api/auth/login') { return [pscustomobject]@{ access_token = 'test-token' } }
                return [pscustomobject]@{ ok = $true }
            }

            $result = Invoke-HomebridgeApiRequest -Url 'https://homebridge.test/' -Credential $credential -Method GET -Path '/api/plugins'

            $result.ok | Should -BeTrue
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -eq 'https://homebridge.test/api/auth/login' -and
                $Body -match 'admin'
            }
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -eq 'https://homebridge.test/api/plugins' -and
                $Headers.Authorization -eq 'Bearer test-token'
            }
        }
    }

    It 'uses the no-auth token endpoint without a credential body' {
        InModuleScope PSHomebridge {
            Mock Invoke-RestMethod {
                if ($Uri -like '*/api/auth/noauth') { return [pscustomobject]@{ access_token = 'noauth-token' } }
                return [pscustomobject]@{ ok = $true }
            }

            Invoke-HomebridgeApiRequest -Url 'https://homebridge.test' -NoAuthentication -Method GET -Path '/api/plugins'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -eq 'https://homebridge.test/api/auth/noauth' -and
                $null -eq $Body
            }
        }
    }

    It 'reauthenticates exactly once after a 401 response' {
        InModuleScope PSHomebridge {
            $secure = ConvertTo-SecureString 'secret-password' -AsPlainText -Force
            $credential = [pscredential]::new('admin', $secure)
            $script:resourceAttempt = 0
            Mock Invoke-RestMethod {
                if ($Uri -like '*/api/auth/login') { return [pscustomobject]@{ access_token = "token-$([guid]::NewGuid())" } }
                if ($script:resourceAttempt++ -eq 0) {
                    throw [System.Net.Http.HttpRequestException]::new(
                        'Unauthorized',
                        $null,
                        [System.Net.HttpStatusCode]::Unauthorized
                    )
                }
                [pscustomobject]@{ ok = $true }
            }

            $requestParameters = @{
                Url        = 'https://homebridge.test'
                Credential = $credential
                Method     = 'GET'
                Path       = '/api/plugins'
            }
            (Invoke-HomebridgeApiRequest @requestParameters).ok | Should -BeTrue

            Should -Invoke Invoke-RestMethod -Times 2 -ParameterFilter { $Uri -eq 'https://homebridge.test/api/auth/login' }
            Should -Invoke Invoke-RestMethod -Times 2 -ParameterFilter { $Uri -eq 'https://homebridge.test/api/plugins' }
        }
    }

    It 'redacts a rejected bearer token from final errors' {
        InModuleScope PSHomebridge -Parameters @{ LogDirectory = (Join-Path $TestDrive 'logs') } {
            param ($LogDirectory)
            $previousLogDirectory = $env:PSHOMEBRIDGE_LOG_DIRECTORY
            $previousLogDisabled = $env:PSHOMEBRIDGE_LOG_DISABLED
            $env:PSHOMEBRIDGE_LOG_DIRECTORY = $LogDirectory
            $env:PSHOMEBRIDGE_LOG_DISABLED = $null
            Mock Invoke-RestMethod {
                if ($Uri -like '*/api/auth/noauth') { return [pscustomobject]@{ access_token = 'recognizable-token' } }
                throw [System.Exception]::new('failure recognizable-token')
            }

            try {
                $requestParameters = @{
                    Url              = 'https://homebridge.test'
                    NoAuthentication = $true
                    Method           = 'GET'
                    Path             = '/api/plugins'
                    ErrorAction      = 'Stop'
                }

                { Invoke-HomebridgeApiRequest @requestParameters } | Should -Throw '*[REDACTED]*'

                $log = Get-Content -LiteralPath (Join-Path $LogDirectory 'PSHomebridge.log') -Raw
                $log | Should -Match '\[REDACTED\]'
                $log | Should -Not -Match 'recognizable-token'
            }
            finally {
                $env:PSHOMEBRIDGE_LOG_DIRECTORY = $previousLogDirectory
                $env:PSHOMEBRIDGE_LOG_DISABLED = $previousLogDisabled
            }
        }
    }

    It 'does not retry a non-authentication failure' {
        InModuleScope PSHomebridge {
            Mock Invoke-RestMethod {
                if ($Uri -like '*/api/auth/noauth') { return [pscustomobject]@{ access_token = 'test-token' } }
                throw [System.Net.Http.HttpRequestException]::new('Server failure', $null, [System.Net.HttpStatusCode]::InternalServerError)
            }

            $requestParameters = @{
                Url              = 'https://homebridge.test'
                NoAuthentication = $true
                Method           = 'GET'
                Path             = '/api/plugins'
                ErrorAction      = 'Stop'
            }
            { Invoke-HomebridgeApiRequest @requestParameters } | Should -Throw

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -eq 'https://homebridge.test/api/auth/noauth' }
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -eq 'https://homebridge.test/api/plugins' }
        }
    }

    It 'does not store tokens from explicit requests in the named-connection cache' {
        InModuleScope PSHomebridge {
            $script:HomebridgeAccessTokens.Clear()
            Mock Invoke-RestMethod {
                if ($Uri -like '*/api/auth/noauth') { return [pscustomobject]@{ access_token = 'explicit-token' } }
                [pscustomobject]@{ ok = $true }
            }

            Invoke-HomebridgeApiRequest -Url 'https://homebridge.test' -NoAuthentication -Method GET -Path '/api/plugins' | Out-Null

            $script:HomebridgeAccessTokens.Count | Should -Be 0
        }
    }

    It 'caches named tokens by connection identity without sharing them' {
        InModuleScope PSHomebridge {
            $script:HomebridgeAccessTokens.Clear()
            Mock Import-Configuration {
                @{ Connections = @{
                        first  = [ordered]@{
                            Url            = 'https://first.test'
                            Authentication = 'None'
                            Username       = $null
                            Secret         = $null
                            ConnectionId   = 'first-id'
                        }
                        second = [ordered]@{
                            Url            = 'https://second.test'
                            Authentication = 'None'
                            Username       = $null
                            Secret         = $null
                            ConnectionId   = 'second-id'
                        }
                    }
                }
            }
            Mock Invoke-RestMethod {
                if ($Uri -eq 'https://first.test/api/auth/noauth') { return [pscustomobject]@{ access_token = 'first-token' } }
                if ($Uri -eq 'https://second.test/api/auth/noauth') { return [pscustomobject]@{ access_token = 'second-token' } }
                [pscustomobject]@{ ok = $true }
            }

            Invoke-HomebridgeApiRequest -InstanceName first -Method GET -Path '/api/plugins' | Out-Null
            Invoke-HomebridgeApiRequest -InstanceName first -Method GET -Path '/api/plugins' | Out-Null
            Invoke-HomebridgeApiRequest -InstanceName second -Method GET -Path '/api/plugins' | Out-Null

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -eq 'https://first.test/api/auth/noauth' }
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -eq 'https://second.test/api/auth/noauth' }
            $script:HomebridgeAccessTokens['first-id'] | Should -Be 'first-token'
            $script:HomebridgeAccessTokens['second-id'] | Should -Be 'second-token'
        }
    }

}

Describe 'Homebridge connection persistence' {
    BeforeEach {
        InModuleScope PSHomebridge {
            $script:testConfiguration = @{ Connections = @{} }
            Mock Import-Configuration { $script:testConfiguration }
            Mock Export-Configuration { $script:testConfiguration = $InputObject }
        }
    }

    It 'round trips multiple named no-auth connections' {
        Set-PSHomebridgeConnection -InstanceName first -Url 'https://first.test/' -NoAuthentication -Confirm:$false | Out-Null
        Set-PSHomebridgeConnection -InstanceName second -Url 'https://second.test' -NoAuthentication -Confirm:$false | Out-Null

        $result = @(Get-PSHomebridgeConnection)
        $result.Count | Should -Be 2
        $result[0].InstanceName | Should -Be 'first'
        $result[1].InstanceName | Should -Be 'second'
    }

    It 'stores an encrypted DPAPI password and returns only a mask' -Skip:(-not $IsWindows) {
        $secure = ConvertTo-SecureString 'secret-password' -AsPlainText -Force
        $credential = [pscredential]::new('admin', $secure)

        $result = Set-PSHomebridgeConnection -InstanceName home -Url 'https://home.test' -Credential $credential -Confirm:$false
        $result.Password | Should -Be '********'
        InModuleScope PSHomebridge {
            $script:testConfiguration.Connections.home.Secret.Mode | Should -Be 'Dpapi'
            $script:testConfiguration.Connections.home.Secret.CipherText | Should -Not -Be 'secret-password'
        }
    }

    It 'preserves omitted fields during a partial update' {
        InModuleScope PSHomebridge {
            $script:testConfiguration.Connections.home = [ordered]@{
                Url            = 'https://old.test'
                Authentication = 'None'
                Username       = $null
                Secret         = $null
                ConnectionId   = 'old-id'
            }
        }

        $result = Set-PSHomebridgeConnection -InstanceName home -Url 'https://new.test' -Confirm:$false

        $result.Url | Should -Be 'https://new.test'
        $result.Authentication | Should -Be 'None'
    }

    It 'supports explicitly selected plaintext storage' {
        $secure = ConvertTo-SecureString 'secret-password' -AsPlainText -Force
        $credential = [pscredential]::new('admin', $secure)

        $connectionParameters = @{
            InstanceName   = 'home'
            Url            = 'https://home.test'
            Credential     = $credential
            EncryptionMode = 'None'
            Confirm        = $false
        }
        $result = Set-PSHomebridgeConnection @connectionParameters

        $result.EncryptionMode | Should -Be 'None'
        InModuleScope PSHomebridge {
            $script:testConfiguration.Connections.home.Secret | Should -Be 'secret-password'
        }
    }

    It 'round trips AES-256 protected passwords' {
        InModuleScope PSHomebridge {
            $previousKey = $env:PSHOMEBRIDGE_AES_KEY
            $env:PSHOMEBRIDGE_AES_KEY = [Convert]::ToBase64String([byte[]](1..32))
            try {
                $protected = Protect-PSHomebridgeConfigurationSecret -Secret 'portable-secret' -EncryptionMode Aes256
                $restored = Unprotect-PSHomebridgeConfigurationSecret -Value $protected
                $restored | Should -Be 'portable-secret'
            }
            finally {
                $env:PSHOMEBRIDGE_AES_KEY = $previousKey
            }
        }
    }

    It 'rejects malformed AES keys without plaintext fallback' {
        InModuleScope PSHomebridge {
            $previousKey = $env:PSHOMEBRIDGE_AES_KEY
            $env:PSHOMEBRIDGE_AES_KEY = [Convert]::ToBase64String([byte[]](1..16))
            try {
                { Protect-PSHomebridgeConfigurationSecret -Secret 'portable-secret' -EncryptionMode Aes256 } | Should -Throw '*32 bytes*'
            }
            finally {
                $env:PSHOMEBRIDGE_AES_KEY = $previousKey
            }
        }
    }
}
