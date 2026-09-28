function Get-PSHomebridgeConnection {
    <#
    .SYNOPSIS
        Retrieves saved PSHomebridge connections without exposing passwords.

    .DESCRIPTION
        This function returns one or all saved connections. Each result contains its name, URL, authentication mode, username, and password storage mode.

        Credential passwords appear as `********`. The function does not decrypt passwords or change saved configuration.

    .PARAMETER InstanceName
        The name of the saved Homebridge connection.

    .EXAMPLE
        Get-PSHomebridgeConnection

        Returns every saved connection with its password redacted.

    .EXAMPLE
        Get-PSHomebridgeConnection -InstanceName 'Home'

        Returns the saved connection named Home with its password redacted.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        [PSHomebridge.Connection]

        This function returns redacted saved-connection configuration objects.
    #>
    [CmdletBinding()]
    [OutputType('PSHomebridge.Connection')]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
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

    $connectionNames = @($configuration.Connections.Keys | Sort-Object)

    if ($PSBoundParameters.ContainsKey('InstanceName')) {
        if (-not $configuration.Connections.Contains($InstanceName)) {
            Write-Warning "Homebridge connection `"$InstanceName`" was not found."
            return
        }

        $connectionNames = @($InstanceName)
    }

    if ($connectionNames.Count -eq 0) {
        Write-Warning 'No Homebridge connections were found. Run "Set-PSHomebridgeConnection" to create a new connection.'
        return
    }

    foreach ($connectionName in $connectionNames) {
        $connection = $configuration.Connections[$connectionName]
        $encryptionMode = if ($connection.Secret -is [System.Collections.IDictionary]) {
            $connection.Secret.Mode
        }
        else {
            'None'
        }

        $redactedPassword = if ($connection.Authentication -eq 'Credential') {
            '********'
        }
        else {
            $null
        }

        $outputConnection = [PSCustomObject]@{
            InstanceName   = $connectionName
            Url            = $connection.Url
            Authentication = $connection.Authentication
            Username       = $connection.Username
            Password       = $redactedPassword
            EncryptionMode = $encryptionMode
        }

        $outputConnection.PSObject.TypeNames.Insert(0, 'PSHomebridge.Connection')
        $outputConnection
    }
}
