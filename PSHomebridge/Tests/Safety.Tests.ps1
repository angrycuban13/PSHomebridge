BeforeAll {
    $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $manifestPath = Join-Path $repositoryRoot 'PSHomebridge/Source/PSHomebridge.psd1'
    Remove-Module PSHomebridge -Force -ErrorAction SilentlyContinue
    Import-Module $manifestPath -Force
}

Describe 'Backup download safety' {
    It 'makes no transport call under WhatIf' {
        InModuleScope PSHomebridge -Parameters @{ Destination = (Join-Path $TestDrive 'successful-backup.tar.gz') } {
            param ($Destination)
            Mock Invoke-HomebridgeApiRequest {}

            Save-HomebridgeBackup -Name home -BackupId one -OutFile $Destination -WhatIf

            Should -Invoke Invoke-HomebridgeApiRequest -Times 0
        }
    }

    It 'refuses to replace an existing file without Force' {
        InModuleScope PSHomebridge -Parameters @{ Destination = (Join-Path $TestDrive 'backup.tar.gz') } {
            param ($Destination)
            Set-Content -LiteralPath $Destination -Value existing
            Mock Invoke-HomebridgeApiRequest {}

            { Save-HomebridgeBackup -Name home -BackupId one -OutFile $Destination -Confirm:$false } | Should -Throw '*already exists*'
            Should -Invoke Invoke-HomebridgeApiRequest -Times 0
        }
    }

    It 'downloads through a temporary sibling and returns the final file' {
        InModuleScope PSHomebridge -Parameters @{ Destination = (Join-Path $TestDrive 'downloaded-backup.tar.gz') } {
            param ($Destination)
            Mock Invoke-HomebridgeApiRequest { Set-Content -LiteralPath $OutFile -Value downloaded }

            $result = Save-HomebridgeBackup -Name home -BackupId 'one two' -OutFile $Destination -Confirm:$false

            $result | Should -BeOfType ([System.IO.FileInfo])
            $result.FullName | Should -Be $Destination
            Get-Content -LiteralPath $Destination | Should -Be downloaded
            Should -Invoke Invoke-HomebridgeApiRequest -Times 1 -ParameterFilter { $Path -eq '/api/backup/scheduled-backups/one%20two' -and $OutFile -ne $Destination }
        }
    }
}

Describe 'Contract and source boundaries' {
    It 'matches implemented routes to API 5.29.0' {
        $apiPath = Join-Path $repositoryRoot 'PSHomebridge/docs/research/api/api.json'
        $api = (Get-Content -LiteralPath $apiPath -Raw | ConvertFrom-Json -Depth 100).swaggerDoc
        $api.info.version | Should -Be '5.29.0'
        foreach ($path in @('/api/plugins', '/api/status/homebridge-version', '/api/backup/scheduled-backups', '/api/backup/scheduled-backups/next', '/api/backup/scheduled-backups/{backupId}')) {
            $api.paths.PSObject.Properties.Name | Should -Contain $path
        }
    }

    It 'keeps direct HTTP in the private transport only' {
        $source = Get-ChildItem (Join-Path $repositoryRoot 'PSHomebridge/Source') -Filter '*.ps1' -Recurse
        $directCallers = @($source | Where-Object { (Get-Content $_.FullName -Raw) -match '(?m)^\s*Invoke-RestMethod\b' })
        $directCallers.Name | Should -Be @('Invoke-HomebridgeHttpRequest.ps1')
    }

    It 'matches each source filename to its function name' {
        foreach ($file in Get-ChildItem (Join-Path $repositoryRoot 'PSHomebridge/Source') -Filter '*.ps1' -Recurse) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref] $tokens, [ref] $errors)
            $functions = @($ast.FindAll({ param ($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true))
            $functions.Count | Should -Be 1
            $functions[0].Name | Should -Be $file.BaseName
        }
    }
}
