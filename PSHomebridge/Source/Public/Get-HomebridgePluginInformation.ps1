function Get-HomebridgePluginInformation {
    <#
    .SYNOPSIS
        Gets metadata for a Homebridge plugin.

    .DESCRIPTION
        This function returns the complete metadata resource selected by Type for one plugin.

        Registry, AvailableVersion, and Release contact external package or source-code providers through Homebridge. Provider availability and rate limits can affect these requests.

    .PARAMETER InstanceName
        The saved connection name.

    .PARAMETER Url
        An explicit Homebridge URL.

    .PARAMETER Credential
        Explicit credentials.

    .PARAMETER NoAuthentication
        Indicates that the server does not require authentication.

    .PARAMETER PluginName
        The package name of the plugin.

    .PARAMETER Type
        Selects the plugin metadata resource that the command returns.

    .PARAMETER ReleaseVersion
        The version or distribution tag used for Release metadata. This parameter is valid only when Type is Release.

    .EXAMPLE
        Get-HomebridgePluginInformation -InstanceName home -PluginName homebridge-example -Type Schema

        Returns the configuration schema supplied by homebridge-example.

    .EXAMPLE
        Get-HomebridgePluginInformation -InstanceName home -PluginName homebridge-example -Type Release -ReleaseVersion latest

        Returns release information for the latest version through Homebridge.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        PSHomebridge.PluginInformation.*.

        This function returns the complete plugin metadata response.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Named')]
    [OutputType('PSHomebridge.PluginInformation')]
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
        $PluginName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Alias', 'AvailableVersion', 'Changelog', 'EditorContext', 'Registry', 'Release', 'Schema')]
        [System.String]
        $Type,

        [Parameter()]
        [ValidateNotNullOrWhiteSpace()]
        [System.String]
        $ReleaseVersion
    )

    if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $PSBoundParameters.ErrorAction
    }
    else {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $ErrorActionPreference
    }

    if ($PSBoundParameters.ContainsKey('ReleaseVersion') -and $Type -ne 'Release') {
        $message = 'ReleaseVersion can be used only when Type is Release.'
        $errorRecordParameters = @{
            Exception    = [System.ArgumentException]::new($message, 'ReleaseVersion')
            Category     = 'InvalidArgument'
            ErrorId      = 'HomebridgePluginReleaseVersionConflict'
            TargetObject = $ReleaseVersion
            Activity     = $MyInvocation.MyCommand.Name
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

    $escapedPluginName = [System.Uri]::EscapeDataString($PluginName)
    $metadataPaths = @{
        Alias            = "/api/plugins/alias/$escapedPluginName"
        AvailableVersion = "/api/plugins/lookup/$escapedPluginName/versions"
        Changelog        = "/api/plugins/changelog/$escapedPluginName"
        EditorContext    = "/api/plugins/$escapedPluginName/editor-context"
        Registry         = "/api/plugins/lookup/$escapedPluginName"
        Release          = "/api/plugins/release/$escapedPluginName"
        Schema           = "/api/plugins/config-schema/$escapedPluginName"
    }

    $request = @{
        Method = 'GET'
        Path   = $metadataPaths[$Type]
    }

    foreach ($key in @('InstanceName', 'Url', 'Credential', 'NoAuthentication')) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $request[$key] = $PSBoundParameters[$key]
        }
    }

    if ($PSBoundParameters.ContainsKey('ReleaseVersion')) {
        $request.Query = @{ version = $ReleaseVersion }
    }

    foreach ($result in (Invoke-HomebridgeApiRequest @request)) {
        if ($null -eq $result) {
            continue
        }

        $result.PSObject.TypeNames.Insert(0, "PSHomebridge.PluginInformation.$Type")
        $result
    }
}
