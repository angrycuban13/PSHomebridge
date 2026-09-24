function Get-HomebridgeConnection {
    <#
    .SYNOPSIS
        Gets named Homebridge connections.
    .DESCRIPTION
        This function returns redacted saved Homebridge connection records.
    .PARAMETER Name
        An optional connection name.
    .EXAMPLE
        Get-HomebridgeConnection
    .EXAMPLE
        Get-HomebridgeConnection -Name home
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        PSHomebridge.Connection. This function returns redacted connections.
    #>
    [CmdletBinding()]
    [OutputType('PSHomebridge.Connection')]
    param (
        [Parameter(Position = 0)]
        [ValidatePattern('.*\S.*')]
        [System.String]
        $Name
    )

    $originalErrorAction = if ($PSBoundParameters.ContainsKey('ErrorAction')) { [System.Management.Automation.ActionPreference] $PSBoundParameters.ErrorAction } else { [System.Management.Automation.ActionPreference] $ErrorActionPreference }
    $ErrorActionPreference = 'Stop'

    try {
        $store = Import-HomebridgeConfiguration
    }
    catch {
        $exception = [System.InvalidOperationException]::new('Unable to load the saved Homebridge connection configuration.', $_.Exception)
        $errorRecord = New-HomebridgeErrorRecord -Exception $exception -Category ReadError -ErrorId 'HomebridgeConfigurationReadFailed' -TargetObject $Name -Activity $MyInvocation.MyCommand.Name
        Invoke-HomebridgeErrorHandler -Cmdlet $PSCmdlet -ErrorRecord $errorRecord -OriginalErrorAction $originalErrorAction
        return
    }
    $names = if ($PSBoundParameters.ContainsKey('Name')) { @($Name) } else { @($store.Connections.Keys | Sort-Object) }

    foreach ($connectionName in $names) {
        if (-not $store.Connections.Contains($connectionName)) {
            throw "Homebridge connection '$connectionName' was not found."
        }

        ConvertTo-HomebridgeConnectionOutput -Name $connectionName -Record $store.Connections[$connectionName]
    }
}
