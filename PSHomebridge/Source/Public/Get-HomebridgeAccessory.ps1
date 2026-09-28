function Get-HomebridgeAccessory {
    <#
    .SYNOPSIS
        Gets Homebridge accessories.

    .DESCRIPTION
        This function returns all accessories or one accessory selected by UniqueId. It preserves every property returned by Homebridge.

        A request for one accessory refreshes its characteristics. That request can contact or wake the physical device and can fail when the device is unavailable.

    .PARAMETER InstanceName
        The saved connection name.

    .PARAMETER Url
        An explicit Homebridge URL.

    .PARAMETER Credential
        Explicit credentials.

    .PARAMETER NoAuthentication
        Indicates authentication is disabled.

    .PARAMETER UniqueId
        The unique accessory identifier. When omitted, the function returns all accessories.

    .EXAMPLE
        Get-HomebridgeAccessory -InstanceName home

        Returns all accessories from the saved instance.

    .EXAMPLE
        Get-HomebridgeAccessory -InstanceName home -UniqueId 'accessory-id'

        Refreshes and returns the accessory with the specified unique identifier.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        PSHomebridge.Accessory.

        This function returns complete accessory objects.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Named')]
    [OutputType('PSHomebridge.Accessory')]
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

        [Parameter()]
        [ValidateNotNullOrWhiteSpace()]
        [System.String]
        $UniqueId
    )

    $path = if ($PSBoundParameters.ContainsKey('UniqueId')) {
        "/api/accessories/$([System.Uri]::EscapeDataString($UniqueId))"
    }
    else {
        '/api/accessories'
    }

    $request = @{
        Method = 'GET'
        Path   = $path
    }

    foreach ($key in @('InstanceName', 'Url', 'Credential', 'NoAuthentication')) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $request[$key] = $PSBoundParameters[$key]
        }
    }

    foreach ($accessory in (Invoke-HomebridgeApiRequest @request)) {
        if ($null -eq $accessory) {
            continue
        }

        $accessory.PSObject.TypeNames.Insert(0, 'PSHomebridge.Accessory')
        $accessory
    }
}
