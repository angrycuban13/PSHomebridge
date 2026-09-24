function ConvertTo-HomebridgeConnectionOutput {
    <#
    .SYNOPSIS
        Converts a saved record for display.
    .DESCRIPTION
        This function returns a typed connection object without exposing credentials.
    .PARAMETER Name
        The saved connection name.
    .PARAMETER Record
        The saved connection record.
    .EXAMPLE
        ConvertTo-HomebridgeConnectionOutput -Name home -Record $record
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        PSHomebridge.Connection. This function returns a redacted connection.
    #>
    [CmdletBinding()]
    [OutputType('PSHomebridge.Connection')]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]
        $Record
    )

    $result = [PSCustomObject]@{
        Name           = $Name
        Url            = $Record.Url
        Authentication = $Record.Authentication
        Username       = $Record.Username
        Password       = if ($Record.Authentication -eq 'Credential') { '********' } else { $null }
        EncryptionMode = if ($Record.Secret -is [System.Collections.IDictionary]) { $Record.Secret.Mode } elseif ($null -ne $Record.Secret) { 'None' } else { $null }
        ConnectionId   = $Record.ConnectionId
    }

    $result.PSObject.TypeNames.Insert(0, 'PSHomebridge.Connection')
    $result
}
