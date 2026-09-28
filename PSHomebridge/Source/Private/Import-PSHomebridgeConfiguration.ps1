function Import-PSHomebridgeConfiguration {
    <#
    .SYNOPSIS
        Imports persisted PSHomebridge configuration.

    .DESCRIPTION
        This function imports saved connection records without decrypting their secrets.

    .EXAMPLE
        Import-PSHomebridgeConfiguration

        Returns the persisted PSHomebridge connection records without decrypting passwords.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        System.Collections.Hashtable.

        This function returns raw connection configuration.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param ()

    $configuration = Import-Configuration -CompanyName 'AngryCuban13' -Name 'PSHomebridge'

    if ($null -eq $configuration) {
        return @{ Connections = @{} }
    }

    if (-not $configuration.ContainsKey('Connections') -or $null -eq $configuration.Connections) {
        $configuration.Connections = @{}
    }

    if ($configuration.Connections -isnot [System.Collections.IDictionary]) {
        throw 'The saved Homebridge connection configuration is invalid.'
    }

    $configuration
}
