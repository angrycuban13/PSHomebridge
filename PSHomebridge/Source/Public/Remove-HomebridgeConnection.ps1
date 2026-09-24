function Remove-HomebridgeConnection {
    <#
    .SYNOPSIS
        Removes a named Homebridge connection.
    .DESCRIPTION
        This function removes one saved connection and its cached access token.
    .PARAMETER Name
        The connection name to remove.
    .EXAMPLE
        Remove-HomebridgeConnection -Name home
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        None. This function removes configuration.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
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

    if (-not $store.Connections.Contains($Name)) {
        throw "Homebridge connection '$Name' was not found."
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Remove Homebridge connection')) {
        $connectionId = $store.Connections[$Name].ConnectionId
        $store.Connections.Remove($Name)
        try {
            Export-Configuration -InputObject $store -CompanyName 'AngryCuban13' -Name 'PSHomebridge' -Scope User -AsHashtable
        }
        catch {
            $exception = [System.InvalidOperationException]::new("Unable to remove Homebridge connection '$Name'.", $_.Exception)
            $errorRecord = New-HomebridgeErrorRecord -Exception $exception -Category WriteError -ErrorId 'HomebridgeConfigurationWriteFailed' -TargetObject $Name -Activity $MyInvocation.MyCommand.Name
            Invoke-HomebridgeErrorHandler -Cmdlet $PSCmdlet -ErrorRecord $errorRecord -OriginalErrorAction $originalErrorAction
            return
        }
        $script:HomebridgeAccessTokens.Remove($connectionId)
    }
}
