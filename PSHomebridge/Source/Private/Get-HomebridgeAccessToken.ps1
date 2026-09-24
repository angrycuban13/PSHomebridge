function Get-HomebridgeAccessToken {
    <#
    .SYNOPSIS
        Gets a Homebridge access token.
    .DESCRIPTION
        This function authenticates a resolved connection and caches named-connection tokens in memory.
    .PARAMETER Connection
        The resolved connection record.
    .PARAMETER Force
        Ignores a cached token.
    .EXAMPLE
        Get-HomebridgeAccessToken -Connection $connection
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.String. This function returns a bearer token.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Connection,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if (-not $Force -and $script:HomebridgeAccessTokens.ContainsKey($Connection.CacheKey)) {
        return $script:HomebridgeAccessTokens[$Connection.CacheKey]
    }

    $plainPassword = $null

    try {
        if ($Connection.Authentication -eq 'Credential') {
            $plainPassword = $Connection.Credential.GetNetworkCredential().Password
            $parameters = @{
                Uri         = "$($Connection.Url)/api/auth/login"
                Method      = 'POST'
                ContentType = 'application/json'
                Body        = @{ username = $Connection.Credential.UserName; password = $plainPassword } | ConvertTo-Json
                ErrorAction = 'Stop'
            }
        }
        else {
            $parameters = @{
                Uri         = "$($Connection.Url)/api/auth/noauth"
                Method      = 'POST'
                ContentType = 'application/json'
                ErrorAction = 'Stop'
            }
        }

        $response = Invoke-HomebridgeHttpRequest -Parameters $parameters
        $token = [System.String] $response.access_token

        if ([System.String]::IsNullOrWhiteSpace($token)) {
            throw 'The authentication response did not contain an access token.'
        }

        $script:HomebridgeAccessTokens[$Connection.CacheKey] = $token
        $token
    }
    catch {
        $message = Protect-HomebridgeErrorMessage -Message $_.Exception.Message -Secret @($plainPassword)
        throw [System.Security.Authentication.AuthenticationException]::new("Homebridge authentication failed. $message", $_.Exception)
    }
    finally {
        $plainPassword = $null
        if ($null -ne $parameters -and $parameters.ContainsKey('Body')) { $parameters.Body = $null }
    }
}
