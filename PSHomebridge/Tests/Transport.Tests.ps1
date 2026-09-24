BeforeAll {
    $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $manifestPath = Join-Path $repositoryRoot 'PSHomebridge/Source/PSHomebridge.psd1'
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
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -eq 'https://homebridge.test/api/auth/login' -and $Body -match 'admin' }
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -eq 'https://homebridge.test/api/plugins' -and $Headers.Authorization -eq 'Bearer test-token' }
        }
    }

    It 'uses the no-auth token endpoint without a credential body' {
        InModuleScope PSHomebridge {
            Mock Invoke-RestMethod {
                if ($Uri -like '*/api/auth/noauth') { return [pscustomobject]@{ access_token = 'noauth-token' } }
                return [pscustomobject]@{ ok = $true }
            }

            Invoke-HomebridgeApiRequest -Url 'https://homebridge.test' -NoAuthentication -Method GET -Path '/api/plugins'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -eq 'https://homebridge.test/api/auth/noauth' -and $null -eq $Body }
        }
    }

    It 'reauthenticates exactly once after a 401 response' {
        InModuleScope PSHomebridge {
            $secure = ConvertTo-SecureString 'secret-password' -AsPlainText -Force
            $credential = [pscredential]::new('admin', $secure)
            $script:resourceAttempt = 0
            Mock Invoke-RestMethod {
                if ($Uri -like '*/api/auth/login') { return [pscustomobject]@{ access_token = "token-$([guid]::NewGuid())" } }
                if ($script:resourceAttempt++ -eq 0) { throw [System.Net.Http.HttpRequestException]::new('Unauthorized', $null, [System.Net.HttpStatusCode]::Unauthorized) }
                [pscustomobject]@{ ok = $true }
            }

            (Invoke-HomebridgeApiRequest -Url 'https://homebridge.test' -Credential $credential -Method GET -Path '/api/plugins').ok | Should -BeTrue

            Should -Invoke Invoke-RestMethod -Times 2 -ParameterFilter { $Uri -eq 'https://homebridge.test/api/auth/login' }
            Should -Invoke Invoke-RestMethod -Times 2 -ParameterFilter { $Uri -eq 'https://homebridge.test/api/plugins' }
        }
    }

    It 'redacts a rejected bearer token from final errors' {
        InModuleScope PSHomebridge {
            Mock Invoke-RestMethod {
                if ($Uri -like '*/api/auth/noauth') { return [pscustomobject]@{ access_token = 'recognizable-token' } }
                throw [System.Exception]::new('failure recognizable-token')
            }

            { Invoke-HomebridgeApiRequest -Url 'https://homebridge.test' -NoAuthentication -Method GET -Path '/api/plugins' -ErrorAction Stop } |
                Should -Throw '*[REDACTED]*'
        }
    }

    It 'does not retry a non-authentication failure' {
        InModuleScope PSHomebridge {
            Mock Invoke-RestMethod {
                if ($Uri -like '*/api/auth/noauth') { return [pscustomobject]@{ access_token = 'test-token' } }
                throw [System.Net.Http.HttpRequestException]::new('Server failure', $null, [System.Net.HttpStatusCode]::InternalServerError)
            }

            { Invoke-HomebridgeApiRequest -Url 'https://homebridge.test' -NoAuthentication -Method GET -Path '/api/plugins' -ErrorAction Stop } | Should -Throw

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -eq 'https://homebridge.test/api/auth/noauth' }
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -eq 'https://homebridge.test/api/plugins' }
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
        New-HomebridgeConnection -Name first -Url 'https://first.test/' -NoAuthentication -Confirm:$false | Out-Null
        New-HomebridgeConnection -Name second -Url 'https://second.test' -NoAuthentication -Confirm:$false | Out-Null

        $result = @(Get-HomebridgeConnection)
        $result.Count | Should -Be 2
        $result[0].Name | Should -Be 'first'
        $result[1].Name | Should -Be 'second'
    }

    It 'stores an encrypted DPAPI password and returns only a mask' -Skip:(-not $IsWindows) {
        $secure = ConvertTo-SecureString 'secret-password' -AsPlainText -Force
        $credential = [pscredential]::new('admin', $secure)

        $result = New-HomebridgeConnection -Name home -Url 'https://home.test' -Credential $credential -Confirm:$false
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

        $result = Set-HomebridgeConnection -Name home -Url 'https://new.test' -Confirm:$false

        $result.Url | Should -Be 'https://new.test'
        $result.Authentication | Should -Be 'None'
    }

    It 'requires explicit consent for plaintext storage' {
        $secure = ConvertTo-SecureString 'secret-password' -AsPlainText -Force
        $credential = [pscredential]::new('admin', $secure)

        { New-HomebridgeConnection -Name home -Url 'https://home.test' -Credential $credential -EncryptionMode None -Confirm:$false } |
            Should -Throw '*AllowPlaintext*'
    }

    It 'round trips AES-256 protected passwords' {
        InModuleScope PSHomebridge {
            $previousKey = $env:PSHOMEBRIDGE_AES_KEY
            $env:PSHOMEBRIDGE_AES_KEY = [Convert]::ToBase64String([byte[]](1..32))
            try {
                $secure = ConvertTo-SecureString 'portable-secret' -AsPlainText -Force
                $protected = Protect-HomebridgeSecret -SecureString $secure -EncryptionMode Aes256
                $restored = Unprotect-HomebridgeSecret -Value $protected
                [System.Net.NetworkCredential]::new('', $restored).Password | Should -Be 'portable-secret'
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
                $secure = ConvertTo-SecureString 'portable-secret' -AsPlainText -Force
                { Protect-HomebridgeSecret -SecureString $secure -EncryptionMode Aes256 } | Should -Throw '*32 bytes*'
            }
            finally {
                $env:PSHOMEBRIDGE_AES_KEY = $previousKey
            }
        }
    }
}
