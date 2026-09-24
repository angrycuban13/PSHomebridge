function Resolve-HomebridgeConnection {
    <#
    .SYNOPSIS
        Resolves connection parameters.
    .DESCRIPTION
        This function resolves one named or explicit Homebridge connection into an internal record.
    .PARAMETER Name
        The saved connection name.
    .PARAMETER Url
        An explicit Homebridge base URL.
    .PARAMETER Credential
        Explicit credentials.
    .PARAMETER NoAuthentication
        Indicates authentication is disabled.
    .EXAMPLE
        Resolve-HomebridgeConnection -Name home
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.Management.Automation.PSCustomObject. This function returns a resolved connection.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Named')]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'Named')]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitCredential')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitNoAuthentication')]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitNoAuthentication')]
        [System.Management.Automation.SwitchParameter]
        $NoAuthentication
    )

    if ($PSCmdlet.ParameterSetName -eq 'Named') {
        $store = Import-HomebridgeConfiguration
        $names = @($store.Connections.Keys | Sort-Object)

        if ($PSBoundParameters.ContainsKey('Name')) {
            if (-not $store.Connections.Contains($Name)) { throw "Homebridge connection '$Name' was not found." }
            $resolvedName = $Name
        }
        elseif ($names.Count -eq 1) {
            $resolvedName = $names[0]
        }
        elseif ($names.Count -eq 0) {
            throw 'No Homebridge connections were found.'
        }
        else {
            throw "Multiple Homebridge connections exist: $($names -join ', '). Specify Name."
        }

        $record = $store.Connections[$resolvedName]
        $resolvedCredential = if ($record.Authentication -eq 'Credential') {
            [System.Management.Automation.PSCredential]::new($record.Username, (Unprotect-HomebridgeSecret -Value $record.Secret))
        }
        else { $null }

        return [PSCustomObject]@{
            Name           = $resolvedName
            Url            = $record.Url
            Authentication = $record.Authentication
            Credential     = $resolvedCredential
            CacheKey       = $record.ConnectionId
            Cacheable      = $true
        }
    }

    [PSCustomObject]@{
        Name           = $null
        Url            = $Url.TrimEnd('/')
        Authentication = if ($PSCmdlet.ParameterSetName -eq 'ExplicitNoAuthentication') { 'None' } else { 'Credential' }
        Credential     = $Credential
        CacheKey       = [System.Guid]::NewGuid().ToString('N')
        Cacheable      = $false
    }
}
