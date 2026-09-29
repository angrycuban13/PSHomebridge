function Find-HomebridgePlugin {
    <#
    .SYNOPSIS
        Finds Homebridge plugins in the package registry.

    .DESCRIPTION
        This function asks Homebridge to search the NPM registry and returns complete matching plugin objects.

        The request contacts an external package provider. Provider availability and rate limits can affect the request.

    .PARAMETER InstanceName
        The saved connection name.

    .PARAMETER Url
        An explicit Homebridge URL.

    .PARAMETER Credential
        Explicit credentials.

    .PARAMETER NoAuthentication
        Indicates that the server does not require authentication.

    .PARAMETER Query
        The plugin search text.

    .EXAMPLE
        Find-HomebridgePlugin -InstanceName home -Query camera

        Returns Homebridge plugins matching camera from the NPM registry.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        PSHomebridge.PluginSearchResult.

        This function returns complete plugin search-result objects.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Named')]
    [OutputType('PSHomebridge.PluginSearchResult')]
    param(
        [Parameter(ParameterSetName = 'Named')]
        [ValidatePattern('.*\S.*')]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitCredential')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitNoAuthentication')]
        [ValidateScript({ Test-PSHomebridgeUrl -Url $_ })]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitNoAuthentication')]
        [System.Management.Automation.SwitchParameter]
        $NoAuthentication,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [System.String]
        $Query
    )

    $escapedQuery = [System.Uri]::EscapeDataString($Query)
    $request = @{
        Method = 'GET'
        Path   = "/api/plugins/search/$escapedQuery"
    }

    foreach ($key in @('InstanceName', 'Url', 'Credential', 'NoAuthentication')) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $request[$key] = $PSBoundParameters[$key]
        }
    }

    foreach ($result in (Invoke-HomebridgeApiRequest @request)) {
        if ($null -eq $result) {
            continue
        }

        $result.PSObject.TypeNames.Insert(0, 'PSHomebridge.PluginSearchResult')
        $result
    }
}
