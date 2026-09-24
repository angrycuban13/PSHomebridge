function Get-HomebridgeStatus {
    <#
    .SYNOPSIS
        Gets Homebridge status information.
    .DESCRIPTION
        This function returns the complete response for an approved status type.
    .PARAMETER Name
        The saved connection name.
    .PARAMETER Url
        An explicit Homebridge URL.
    .PARAMETER Credential
        Explicit credentials.
    .PARAMETER NoAuthentication
        Indicates authentication is disabled.
    .PARAMETER Type
        The status resource to retrieve.
    .EXAMPLE
        Get-HomebridgeStatus -Name home -Type HomebridgeVersion
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        PSHomebridge.Status.HomebridgeVersion. This function returns the complete status object.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Named')]
    [OutputType('PSHomebridge.Status.HomebridgeVersion')]
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('HomebridgeVersion')]
        [System.String]
        $Type
    )

    $request = @{ Method = 'GET'; Path = '/api/status/homebridge-version' }
    foreach ($key in @('Name', 'Url', 'Credential', 'NoAuthentication')) { if ($PSBoundParameters.ContainsKey($key)) { $request[$key] = $PSBoundParameters[$key] } }
    $result = Invoke-HomebridgeApiRequest @request

    if ($null -ne $result) {
        $result.PSObject.TypeNames.Insert(0, 'PSHomebridge.Status.HomebridgeVersion')
        $result
    }
}
