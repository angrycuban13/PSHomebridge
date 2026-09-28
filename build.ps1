[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('Build', 'Test', 'Clean', 'Verify')]
    [System.String]
    $Task = 'Build'
)

$sourceDirectory = Join-Path $PSScriptRoot 'PSHomebridge/Source'
$manifestPath = Join-Path $sourceDirectory 'PSHomebridge.psd1'
$version = (Import-PowerShellDataFile -Path $manifestPath).ModuleVersion
$outputRoot = Join-Path $PSScriptRoot 'PSHomebridge/Output/PSHomebridge'
$outputDirectory = Join-Path $outputRoot $version

function Invoke-Build {
    $buildConfiguration = Join-Path $PSScriptRoot 'PSHomebridge/build.psd1'
    Build-Module -SourcePath $buildConfiguration
    Test-ModuleManifest -Path (Join-Path $outputDirectory 'PSHomebridge.psd1') -ErrorAction Stop | Out-Null
}

switch ($Task) {
    'Build' {
        Invoke-Build
    }
    'Test' {
        Invoke-Build
        Invoke-Pester -Path (Join-Path $PSScriptRoot 'PSHomebridge/Tests')
    }
    'Clean' {
        if (Test-Path -LiteralPath $outputRoot) {
            Remove-Item -LiteralPath $outputRoot -Recurse -Force
        }
    }
    'Verify' {
        Invoke-Build

        if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
            $settingsPath = Join-Path $PSScriptRoot '.vscode/PSScriptAnalyzerSettings.psd1'
            $analysis = @(Invoke-ScriptAnalyzer -Path $sourceDirectory -Recurse -Settings $settingsPath -Severity Warning, Error)
            if ($analysis.Count -gt 0) {
                $analysis | Format-Table -AutoSize
                throw "PSScriptAnalyzer reported $($analysis.Count) issue(s)."
            }
        }

        if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'PSHomebridge/Tests')) {
            $result = Invoke-Pester -Path (Join-Path $PSScriptRoot 'PSHomebridge/Tests') -PassThru
            if ($result.FailedCount -gt 0) {
                throw "Pester reported $($result.FailedCount) failed test(s)."
            }
        }

        $unexpectedFiles = @(
            Get-ChildItem -LiteralPath $outputDirectory -File -Recurse | Where-Object {
                $_.Extension -notin @('.ps1', '.psd1', '.psm1', '.ps1xml')
            }
        )
        if ($unexpectedFiles.Count -gt 0) {
            throw "The package contains unexpected files: $($unexpectedFiles.FullName -join ', ')."
        }
    }
}
