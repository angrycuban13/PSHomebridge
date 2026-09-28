function Get-HomebridgeServerDiagnostic {
    <#
    .SYNOPSIS
        Gets Homebridge server diagnostic information.

    .DESCRIPTION
        This function returns the complete server diagnostic resource selected by Type and does not change the instance.

        Pairing data can contain sensitive setup information. The function does not write successful responses to the operational log.

    .PARAMETER InstanceName
        The saved connection name.

    .PARAMETER Url
        An explicit Homebridge URL.

    .PARAMETER Credential
        Explicit credentials.

    .PARAMETER NoAuthentication
        Indicates authentication is disabled.

    .PARAMETER Type
        The server diagnostic resource to retrieve.

    .EXAMPLE
        Get-HomebridgeServerDiagnostic -InstanceName home -Type NetworkOverview

        Returns port assignments, Matter diagnostics, and detected network conflicts.

    .EXAMPLE
        Get-HomebridgeServerDiagnostic -InstanceName home -Type Pairing

        Returns the Homebridge and HomeKit pairing status.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        PSHomebridge.ServerDiagnostic.*.

        This function returns complete server diagnostic objects.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Named')]
    [OutputType('PSHomebridge.ServerDiagnostic')]
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
        [ValidateSet(
            'AccessoryOverview',
            'BridgeNetworkInterface',
            'CachedAccessory',
            'MatterAccessory',
            'MdnsAdvertiser',
            'NetworkOverview',
            'Pairing',
            'PairingList',
            'Port',
            'PortRange',
            'SystemNetworkInterface'
        )]
        [System.String]
        $Type
    )

    $diagnosticPaths = @{
        AccessoryOverview      = '/api/server/accessory-overview'
        BridgeNetworkInterface = '/api/server/network-interfaces/bridge'
        CachedAccessory        = '/api/server/cached-accessories'
        MatterAccessory        = '/api/server/matter-accessories'
        MdnsAdvertiser         = '/api/server/mdns-advertiser'
        NetworkOverview        = '/api/server/network/overview'
        Pairing                = '/api/server/pairing'
        PairingList            = '/api/server/pairings'
        Port                   = '/api/server/port'
        PortRange              = '/api/server/ports'
        SystemNetworkInterface = '/api/server/network-interfaces/system'
    }

    $request = @{
        Method = 'GET'
        Path   = $diagnosticPaths[$Type]
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

        $result.PSObject.TypeNames.Insert(0, "PSHomebridge.ServerDiagnostic.$Type")
        $result
    }
}
