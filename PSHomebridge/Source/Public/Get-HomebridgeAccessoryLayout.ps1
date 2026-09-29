function Get-HomebridgeAccessoryLayout {
    <#
    .SYNOPSIS
        Gets the Homebridge accessory layout.

    .DESCRIPTION
        This function returns the accessory and room layout for the authenticating user. It preserves every property returned by Homebridge.

    .PARAMETER InstanceName
        The saved connection name.

    .PARAMETER Url
        An explicit Homebridge URL.

    .PARAMETER Credential
        Explicit credentials.

    .PARAMETER NoAuthentication
        Indicates that the server does not require authentication.

    .EXAMPLE
        Get-HomebridgeAccessoryLayout -InstanceName home

        Returns the saved accessory and room layout for the current user.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        PSHomebridge.AccessoryLayout.

        This function returns complete accessory-layout objects.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Named')]
    [OutputType('PSHomebridge.AccessoryLayout')]
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
        $NoAuthentication
    )

    $request = @{
        Method = 'GET'
        Path   = '/api/accessories/layout'
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

        $result.PSObject.TypeNames.Insert(0, 'PSHomebridge.AccessoryLayout')
        $result
    }
}
