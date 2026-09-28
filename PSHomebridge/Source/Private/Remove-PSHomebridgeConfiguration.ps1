function Remove-PSHomebridgeConfiguration {
    <#
    .SYNOPSIS
        Removes the final PSHomebridge configuration file.

    .DESCRIPTION
        This function removes the saved configuration file and empty parent directories. It rejects paths outside the expected company and module directories.

    .PARAMETER Module
        The loaded PSHomebridge module that owns the configuration.

    .EXAMPLE
        Remove-PSHomebridgeConfiguration -Module (Get-Module -Name PSHomebridge)

        Removes the final saved configuration and any empty configuration directories.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        None.

        This function does not return objects to the pipeline.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'The public caller completes ShouldProcess before it calls this internal cleanup function.')]
    [CmdletBinding()]
    [OutputType([System.Void])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSModuleInfo]
        $Module
    )

    $configurationPath = $Module | Get-ConfigurationPath -Scope User -SkipCreatingFolder
    $configurationFile = Join-Path -Path $configurationPath -ChildPath 'Configuration.psd1'
    $companyPath = Split-Path -Path $configurationPath -Parent

    # Restrict deletion to the configuration directories owned by this module.
    if ((Split-Path -Path $configurationPath -Leaf) -ne $Module.Name -or
        (Split-Path -Path $companyPath -Leaf) -ne $Module.CompanyName) {
        throw "Configuration returned an unexpected path: '$configurationPath'."
    }

    if (Test-Path -LiteralPath $configurationFile -PathType Leaf) {
        Remove-Item -LiteralPath $configurationFile -Force -ErrorAction Stop
    }

    foreach ($directory in @($configurationPath, $companyPath)) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            continue
        }

        $children = @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)

        if ($children.Count -eq 0) {
            Remove-Item -LiteralPath $directory -Force -ErrorAction Stop
        }
    }
}
