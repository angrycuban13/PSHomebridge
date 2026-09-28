function Remove-PSHomebridgeConnection {
    <#
    .SYNOPSIS
        Removes a saved Homebridge connection.

    .DESCRIPTION
        This function removes one saved connection and its retained authorization. It removes empty PSHomebridge configuration directories after the last connection.

        A missing connection produces a warning. The operation supports ShouldProcess and does not return an object.

    .PARAMETER InstanceName
        The name of the saved Homebridge connection.

    .EXAMPLE
        Remove-PSHomebridgeConnection -InstanceName 'Home' -Confirm:$false

        Removes the saved Homebridge connection named Home without prompting.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        None.

        This function does not return objects to the pipeline.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([System.Void])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrWhiteSpace()]
        [System.String]
        $InstanceName
    )

    if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $PSBoundParameters.ErrorAction
    }
    else {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $ErrorActionPreference
    }

    $ErrorActionPreference = 'Stop'

    try {
        $configuration = Import-PSHomebridgeConfiguration
    }
    catch {
        $message = "Unable to load the saved Homebridge connection configuration. $($_.Exception.Message)"
        $exception = [System.InvalidOperationException]::new($message, $_.Exception)
        $errorRecordParameters = @{
            Exception    = $exception
            Category     = 'ReadError'
            ErrorId      = 'HomebridgeConfigurationReadFailed'
            TargetObject = $InstanceName
            Activity     = $MyInvocation.MyCommand.Name
        }
        $errorRecord = New-PSHomebridgeErrorRecord @errorRecordParameters

        $errorHandlerParameters = @{
            Cmdlet              = $PSCmdlet
            ErrorRecord         = $errorRecord
            OriginalErrorAction = $originalErrorAction
            LogMessage          = $message
        }
        Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
        return
    }

    if (-not $configuration.Connections.Contains($InstanceName)) {
        Write-Warning "Homebridge connection '$InstanceName' was not found."
        return
    }

    if (-not $PSCmdlet.ShouldProcess($InstanceName, 'Remove Homebridge connection')) {
        return
    }

    $connectionId = $configuration.Connections[$InstanceName].ConnectionId
    $configuration.Connections.Remove($InstanceName)

    if ($configuration.Connections.Count -gt 0) {
        try {
            $exportParameters = @{
                InputObject = $configuration
                CompanyName = 'AngryCuban13'
                Name        = 'PSHomebridge'
                Scope       = 'User'
                AsHashtable = $true
            }
            Export-Configuration @exportParameters
        }
        catch {
            $message = "Unable to save the Homebridge connection configuration after removing '$InstanceName'. $($_.Exception.Message)"
            $exception = [System.InvalidOperationException]::new($message, $_.Exception)
            $errorRecordParameters = @{
                Exception    = $exception
                Category     = 'WriteError'
                ErrorId      = 'HomebridgeConfigurationWriteFailed'
                TargetObject = $InstanceName
                Activity     = $MyInvocation.MyCommand.Name
            }
            $errorRecord = New-PSHomebridgeErrorRecord @errorRecordParameters

            $errorHandlerParameters = @{
                Cmdlet              = $PSCmdlet
                ErrorRecord         = $errorRecord
                OriginalErrorAction = $originalErrorAction
                LogMessage          = $message
            }
            Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
        }

        [void] $script:HomebridgeAccessTokens.Remove($connectionId)
        return
    }

    $module = Get-Module -Name PSHomebridge

    if ($null -eq $module) {
        $message = 'Unable to resolve the loaded PSHomebridge module.'
        $exception = [System.InvalidOperationException]::new($message)
        $errorRecordParameters = @{
            Exception    = $exception
            Category     = 'ResourceUnavailable'
            ErrorId      = 'HomebridgeModuleNotLoaded'
            TargetObject = 'PSHomebridge'
            Activity     = $MyInvocation.MyCommand.Name
        }
        $errorRecord = New-PSHomebridgeErrorRecord @errorRecordParameters

        $errorHandlerParameters = @{
            Cmdlet              = $PSCmdlet
            ErrorRecord         = $errorRecord
            OriginalErrorAction = $originalErrorAction
            LogMessage          = $message
        }
        Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
        return
    }

    try {
        Remove-PSHomebridgeConfiguration -Module $module
    }
    catch {
        $message = "Unable to remove the final Homebridge connection configuration. $($_.Exception.Message)"
        $exception = [System.IO.IOException]::new($message, $_.Exception)
        $errorRecordParameters = @{
            Exception    = $exception
            Category     = 'WriteError'
            ErrorId      = 'HomebridgeConfigurationRemoveFailed'
            TargetObject = $InstanceName
            Activity     = $MyInvocation.MyCommand.Name
        }
        $errorRecord = New-PSHomebridgeErrorRecord @errorRecordParameters

        $errorHandlerParameters = @{
            Cmdlet              = $PSCmdlet
            ErrorRecord         = $errorRecord
            OriginalErrorAction = $originalErrorAction
            LogMessage          = $message
        }
        Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
    }

    [void] $script:HomebridgeAccessTokens.Remove($connectionId)
}
