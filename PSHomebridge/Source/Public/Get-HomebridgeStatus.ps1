function Get-HomebridgeStatus {
    <#
    .SYNOPSIS
        Gets Homebridge status information.

    .DESCRIPTION
        This function returns the complete status object for the selected type and does not change the instance.

    .PARAMETER InstanceName
        The saved connection name.

    .PARAMETER Url
        An explicit Homebridge URL.

    .PARAMETER Credential
        Explicit credentials.

    .PARAMETER NoAuthentication
        Indicates that the server does not require authentication.

    .PARAMETER Type
        Selects the status resource that the command returns. RaspberryPiThrottling is available only when Homebridge runs on a Raspberry Pi.

    .EXAMPLE
        Get-HomebridgeStatus -InstanceName home -Type HomebridgeVersion

        Returns installed and available Homebridge version information from the saved connection.

    .EXAMPLE
        Get-HomebridgeStatus -InstanceName home -Type ChildBridge

        Returns the active child bridges and their current status.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        PSHomebridge.Status.*.

        This function returns the complete status object.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Named')]
    [OutputType('PSHomebridge.Status')]
    param (
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
            'ChildBridge',
            'Cpu',
            'Homebridge',
            'HomebridgeVersion',
            'Memory',
            'Network',
            'NodeJs',
            'RaspberryPiThrottling',
            'ServerInformation',
            'Uptime'
        )]
        [System.String]
        $Type
    )

    if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $PSBoundParameters.ErrorAction
    }
    else {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $ErrorActionPreference
    }

    $statusPaths = @{
        ChildBridge           = '/api/status/homebridge/child-bridges'
        Cpu                   = '/api/status/cpu'
        Homebridge            = '/api/status/homebridge'
        HomebridgeVersion     = '/api/status/homebridge-version'
        Memory                = '/api/status/ram'
        Network               = '/api/status/network'
        NodeJs                = '/api/status/nodejs'
        RaspberryPiThrottling = '/api/status/rpi/throttled'
        ServerInformation     = '/api/status/server-information'
        Uptime                = '/api/status/uptime'
    }

    $request = @{
        Method      = 'GET'
        Path        = $statusPaths[$Type]
        ErrorAction = 'Stop'
    }

    foreach ($key in @('InstanceName', 'Url', 'Credential', 'NoAuthentication')) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $request[$key] = $PSBoundParameters[$key]
        }
    }

    try {
        $results = Invoke-HomebridgeApiRequest @request
    }
    catch {
        if ($Type -eq 'RaspberryPiThrottling' -and $_.Exception.Message -match 'only available on Raspberry Pi') {
            $message = 'Raspberry Pi throttling status is available only when Homebridge runs on a Raspberry Pi.'
            $errorRecordParameters = @{
                Exception         = [System.PlatformNotSupportedException]::new($message)
                Category          = 'NotImplemented'
                ErrorId           = 'HomebridgeStatusUnsupportedPlatform'
                TargetObject      = $Type
                Activity          = $MyInvocation.MyCommand.Name
                RecommendedAction = 'Use this status type only with a Raspberry Pi Homebridge host.'
            }
            $errorRecord = New-PSHomebridgeErrorRecord @errorRecordParameters

            $errorHandlerParameters = @{
                Cmdlet              = $PSCmdlet
                ErrorRecord         = $errorRecord
                OriginalErrorAction = $originalErrorAction
                NoLog               = $true
            }
            Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
            return
        }

        $errorHandlerParameters = @{
            Cmdlet              = $PSCmdlet
            ErrorRecord         = $_
            OriginalErrorAction = $originalErrorAction
            NoLog               = $true
        }
        Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
        return
    }

    foreach ($result in $results) {
        if ($null -eq $result) {
            continue
        }

        $result.PSObject.TypeNames.Insert(0, "PSHomebridge.Status.$Type")
        $result
    }
}
