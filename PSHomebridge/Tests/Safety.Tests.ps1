BeforeAll {
    $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $manifestPath = Join-Path $repositoryRoot 'PSHomebridge/Output/PSHomebridge/1.0.0/PSHomebridge.psd1'
    Remove-Module PSHomebridge -Force -ErrorAction SilentlyContinue
    Import-Module $manifestPath -Force
}

Describe 'Backup download safety' {
    It 'makes no transport call under WhatIf' {
        InModuleScope PSHomebridge -Parameters @{ Destination = (Join-Path $TestDrive 'successful-backup.tar.gz') } {
            param ($Destination)
            Mock Invoke-HomebridgeApiRequest {}

            Save-HomebridgeBackup -InstanceName home -BackupId one -OutFile $Destination -WhatIf

            Should -Invoke Invoke-HomebridgeApiRequest -Times 0
        }
    }

    It 'refuses to replace an existing file without Force' {
        InModuleScope PSHomebridge -Parameters @{ Destination = (Join-Path $TestDrive 'backup.tar.gz') } {
            param ($Destination)
            Set-Content -LiteralPath $Destination -Value existing
            Mock Invoke-HomebridgeApiRequest {}

            $saveParameters = @{
                InstanceName = 'home'
                BackupId     = 'one'
                OutFile      = $Destination
                Confirm      = $false
                ErrorAction  = 'Stop'
            }

            { Save-HomebridgeBackup @saveParameters } | Should -Throw '*already exists*'
            Should -Invoke Invoke-HomebridgeApiRequest -Times 0
        }
    }

    It 'emits a structured nonterminating error for an existing file' {
        InModuleScope PSHomebridge -Parameters @{ Destination = (Join-Path $TestDrive 'existing-backup.tar.gz') } {
            param ($Destination)
            Set-Content -LiteralPath $Destination -Value existing
            Mock Invoke-HomebridgeApiRequest {}
            Mock Write-PSHomebridgeLogEntry {}

            $errors = @()
            $saveParameters = @{
                InstanceName  = 'home'
                BackupId      = 'one'
                OutFile       = $Destination
                Confirm       = $false
                ErrorAction   = 'Continue'
                ErrorVariable = '+errors'
            }
            Save-HomebridgeBackup @saveParameters 2>$null

            $errors.Count | Should -Be 1
            $errors[0].FullyQualifiedErrorId | Should -Match '^HomebridgeBackupDestinationExists'
            $errors[0].CategoryInfo.Category | Should -Be 'ResourceExists'
            Should -Invoke Invoke-HomebridgeApiRequest -Times 0
            Should -Invoke Write-PSHomebridgeLogEntry -Times 0
        }
    }

    It 'emits a structured terminating error for a directory destination' {
        InModuleScope PSHomebridge -Parameters @{ Destination = $TestDrive } {
            param ($Destination)
            Mock Invoke-HomebridgeApiRequest {}
            Mock Write-PSHomebridgeLogEntry {}

            $caughtError = try {
                Save-HomebridgeBackup -InstanceName home -BackupId one -OutFile $Destination -Confirm:$false -ErrorAction Stop
            }
            catch {
                $_
            }

            $caughtError.FullyQualifiedErrorId | Should -Match '^HomebridgeBackupDestinationIsDirectory'
            $caughtError.CategoryInfo.Category | Should -Be 'InvalidArgument'
            Should -Invoke Invoke-HomebridgeApiRequest -Times 0
            Should -Invoke Write-PSHomebridgeLogEntry -Times 0
        }
    }

    It 'downloads through a temporary sibling and returns the final file' {
        InModuleScope PSHomebridge -Parameters @{ Destination = (Join-Path $TestDrive 'downloaded-backup.tar.gz') } {
            param ($Destination)
            Mock Invoke-HomebridgeApiRequest { Set-Content -LiteralPath $OutFile -Value downloaded }

            $result = Save-HomebridgeBackup -InstanceName home -BackupId 'one two' -OutFile $Destination -Confirm:$false

            $result | Should -BeOfType ([System.IO.FileInfo])
            $result.FullName | Should -Be $Destination
            Get-Content -LiteralPath $Destination | Should -Be downloaded
            Should -Invoke Invoke-HomebridgeApiRequest -Times 1 -ParameterFilter {
                $Path -eq '/api/backup/scheduled-backups/one%20two' -and
                $OutFile -ne $Destination
            }
        }
    }
}

Describe 'Final configuration cleanup' {
    It 'removes only the expected empty configuration directories' {
        InModuleScope PSHomebridge -Parameters @{ Root = $TestDrive } {
            param ($Root)
            $module = Get-Module -Name PSHomebridge
            $companyPath = Join-Path $Root $module.CompanyName
            $configurationPath = Join-Path $companyPath $module.Name
            $configurationFile = Join-Path $configurationPath 'Configuration.psd1'
            $null = New-Item -Path $configurationPath -ItemType Directory -Force
            Set-Content -LiteralPath $configurationFile -Value '@{}'
            Mock Get-ConfigurationPath { $configurationPath }

            Remove-PSHomebridgeConfiguration -Module $module

            Test-Path -LiteralPath $configurationFile | Should -BeFalse
            Test-Path -LiteralPath $configurationPath | Should -BeFalse
            Test-Path -LiteralPath $companyPath | Should -BeFalse
        }
    }

    It 'rejects a configuration path outside the expected module directory' {
        InModuleScope PSHomebridge -Parameters @{ Root = $TestDrive } {
            param ($Root)
            $module = Get-Module -Name PSHomebridge
            $unexpectedPath = Join-Path $Root 'Unexpected'
            $null = New-Item -Path $unexpectedPath -ItemType Directory -Force
            Mock Get-ConfigurationPath { $unexpectedPath }

            { Remove-PSHomebridgeConfiguration -Module $module } | Should -Throw '*unexpected path*'
            Test-Path -LiteralPath $unexpectedPath | Should -BeTrue
        }
    }
}

Describe 'Contract and source boundaries' {
    It 'matches implemented routes to API 5.29.0' {
        $apiPath = Join-Path $repositoryRoot 'PSHomebridge/docs/research/api/api.json'
        $api = (Get-Content -LiteralPath $apiPath -Raw | ConvertFrom-Json -Depth 100).swaggerDoc
        $api.info.version | Should -Be '5.29.0'
        $expectedPaths = @(
            '/api/plugins'
            '/api/status/homebridge-version'
            '/api/backup/scheduled-backups'
            '/api/backup/scheduled-backups/next'
            '/api/backup/scheduled-backups/{backupId}'
        )

        foreach ($path in $expectedPaths) {
            $api.paths.PSObject.Properties.Name | Should -Contain $path
        }
    }

    It 'keeps direct HTTP in the public API boundary only' {
        $source = Get-ChildItem (Join-Path $repositoryRoot 'PSHomebridge/Source') -Filter '*.ps1' -Recurse
        $directCallers = @($source | Where-Object { (Get-Content $_.FullName -Raw) -match '\bInvoke-RestMethod\b' })
        $directCallers.Name | Should -Be @('Invoke-HomebridgeApiRequest.ps1')
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

    It 'uses complete paragraph-form help and explained examples' {
        foreach ($file in Get-ChildItem (Join-Path $repositoryRoot 'PSHomebridge/Source') -Filter '*.ps1' -Recurse) {
            $text = Get-Content -LiteralPath $file.FullName -Raw
            $helpLines = @($text -split '\r?\n')
            $sectionIndexes = @(
                for ($index = 0; $index -lt $helpLines.Count; $index++) {
                    if ($helpLines[$index] -match '^\s+\.(SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|INPUTS|OUTPUTS|NOTES|LINK)\b') {
                        $index
                    }
                }
            )

            foreach ($sectionIndex in @($sectionIndexes | Select-Object -Skip 1)) {
                $helpLines[$sectionIndex - 1] | Should -BeNullOrEmpty
            }

            $text | Should -Match '(?ms)\.INPUTS\s*\r?\n\s+[^\r\n]+\r?\n\s*\r?\n\s+[^\r\n]+'
            $text | Should -Match '(?ms)\.OUTPUTS\s*\r?\n\s+[^\r\n]+\r?\n\s*\r?\n\s+[^\r\n]+'

            foreach ($example in [System.Text.RegularExpressions.Regex]::Matches($text, '(?ms)^\s+\.EXAMPLE\s*\r?\n(?<body>.*?)(?=^\s+\.(?:EXAMPLE|INPUTS|OUTPUTS|PARAMETER|LINK)|^\s+#>)')) {
                $exampleBody = $example.Groups['body'].Value
                $contentLines = @($exampleBody -split '\r?\n' | Where-Object { -not [System.String]::IsNullOrWhiteSpace($_) })
                $contentLines.Count | Should -BeGreaterOrEqual 2
                $exampleBody | Should -Match '(?m)^\s+\S.*\r?\n\s*\r?\n\s+\S'
            }
        }
    }
}
