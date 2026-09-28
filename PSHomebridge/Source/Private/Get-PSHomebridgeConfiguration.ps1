function Get-PSHomebridgeConfiguration {
    <#
    .SYNOPSIS
        Retrieves the persisted PSHomebridge configuration.

    .DESCRIPTION
        This function returns saved connections for internal use. It includes decrypted passwords for credential connections and does not change saved configuration.

    .EXAMPLE
        Get-PSHomebridgeConfiguration

        Returns working connection records for API requests.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        [System.Collections.Hashtable]

        This function returns the PSHomebridge configuration as a hashtable.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param()

    $persistedConfiguration = Import-PSHomebridgeConfiguration
    $configuration = @{ Connections = @{} }

    foreach ($connectionName in $persistedConfiguration.Connections.Keys) {
        $persistedConnection = $persistedConfiguration.Connections[$connectionName]
        $password = if ($persistedConnection.Authentication -eq 'Credential') {
            Unprotect-PSHomebridgeConfigurationSecret -Value $persistedConnection.Secret
        }
        else {
            $null
        }
        $configuration.Connections[$connectionName] = [ordered]@{
            Url            = $persistedConnection.Url
            Authentication = $persistedConnection.Authentication
            Username       = $persistedConnection.Username
            Password       = $password
            ConnectionId   = $persistedConnection.ConnectionId
        }
    }

    $configuration
}
