function Get-HomebridgePlugin {
    <#
    .SYNOPSIS
        Gets installed Homebridge plugins.
    .DESCRIPTION
        This function returns complete installed-plugin objects and can filter those with updates available.
    .PARAMETER Name
        The saved connection name.
    .PARAMETER Url
        An explicit Homebridge URL.
    .PARAMETER Credential
        Explicit credentials.
    .PARAMETER NoAuthentication
        Indicates authentication is disabled.
    .PARAMETER Include
        Optional API extras such as config.
    .PARAMETER UpdateAvailable
        Returns only plugins reporting an available update.
    .EXAMPLE
        Get-HomebridgePlugin -Name home -UpdateAvailable
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        PSHomebridge.Plugin. This function returns complete plugin objects.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Named')]
    [OutputType('PSHomebridge.Plugin')]
    param (
        [Parameter(ParameterSetName = 'Named')]
        [ValidatePattern('.*\S.*')]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitCredential')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitNoAuthentication')]
        [ValidateScript({ Test-HomebridgeUrl -Url $_ })]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitNoAuthentication')]
        [System.Management.Automation.SwitchParameter]
        $NoAuthentication,

        [Parameter()]
        [ValidateSet('config')]
        [System.String[]]
        $Include,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UpdateAvailable
    )

    $request = @{ Method = 'GET'; Path = '/api/plugins' }
    foreach ($key in @('Name', 'Url', 'Credential', 'NoAuthentication')) { if ($PSBoundParameters.ContainsKey($key)) { $request[$key] = $PSBoundParameters[$key] } }
    if ($PSBoundParameters.ContainsKey('Include')) { $request.Query = @{ include = $Include -join ',' } }

    foreach ($plugin in @(Invoke-HomebridgeApiRequest @request)) {
        if ($null -eq $plugin -or ($UpdateAvailable -and $plugin.updateAvailable -ne $true)) { continue }
        $plugin.PSObject.TypeNames.Insert(0, 'PSHomebridge.Plugin')
        $plugin
    }
}
