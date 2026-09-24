function Clear-HomebridgeAccessToken {
    <#
    .SYNOPSIS
        Clears one cached access token.
    .DESCRIPTION
        This function removes the token associated with a resolved connection.
    .PARAMETER Connection
        The resolved connection record.
    .EXAMPLE
        Clear-HomebridgeAccessToken -Connection $connection
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        None. This function changes module memory only.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Connection
    )

    $script:HomebridgeAccessTokens.Remove($Connection.CacheKey)
}
