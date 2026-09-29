function Set-PSHomebridgeConnection {
    <#
    .SYNOPSIS
        Creates or updates a saved PSHomebridge connection.

    .DESCRIPTION
        This function creates or updates one saved connection. A new connection requires Url and either Credential or NoAuthentication.

        An existing connection keeps values that the caller omits. Credential passwords use the selected storage mode. The function never saves access tokens.

        The operation supports ShouldProcess. The result contains `********` instead of the password.

    .PARAMETER InstanceName
        The name of the saved Homebridge connection.

    .PARAMETER Url
        The absolute base URL of the Homebridge instance.

    .PARAMETER Credential
        The username and password used to authenticate with Homebridge.

    .PARAMETER NoAuthentication
        Configures an instance with Homebridge authentication disabled.

    .PARAMETER EncryptionMode
        The password storage mode. The default is Dpapi on Windows and None on other platforms. Aes256 requires PSHOMEBRIDGE_AES_KEY to contain exactly 32 Base64-encoded bytes.

    .EXAMPLE
        Set-PSHomebridgeConnection -InstanceName 'Home' -Url 'https://homebridge.example.com' -Credential $credential

        Creates or replaces the authenticated connection named Home.

    .EXAMPLE
        Set-PSHomebridgeConnection -InstanceName 'Home' -Url 'https://homebridge.example.com' -NoAuthentication

        Creates or replaces the connection named Home for an instance with authentication disabled.

    .EXAMPLE
        Set-PSHomebridgeConnection -InstanceName 'Home' -Url 'http://localhost:8582'

        Updates only the URL of an existing connection.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        [PSHomebridge.Connection]

        This function returns a redacted saved-connection configuration object.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType('PSHomebridge.Connection')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrWhiteSpace()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateScript({ Test-PSHomebridgeUrl -Url $_ })]
        [System.String]
        $Url,

        [Parameter(Mandatory = $false, Position = 2)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter]
        $NoAuthentication,

        [Parameter(Mandatory = $false)]
        [ValidateSet('None', 'Dpapi', 'Aes256')]
        [System.String]
        $EncryptionMode
    )

    if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $PSBoundParameters.ErrorAction
    }
    else {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $ErrorActionPreference
    }

    $ErrorActionPreference = 'Stop'

    if (-not $PSCmdlet.ShouldProcess($InstanceName, 'Save Homebridge connection')) {
        return
    }

    $plainPassword = $null

    try {
        $configuration = Import-PSHomebridgeConfiguration
    }
    catch {
        $sensitiveTextParameters = @{
            Text           = "Unable to load the saved Homebridge connection configuration. $($_.Exception.Message)"
            SensitiveValue = @($plainPassword)
        }
        $message = Protect-PSHomebridgeSensitiveText @sensitiveTextParameters
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
            SensitiveValue      = @($plainPassword)
        }
        Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
        return
    }

    $connectionExists = $configuration.Connections.Contains($InstanceName)

    if ($PSBoundParameters.ContainsKey('Credential') -and $NoAuthentication) {
        $message = 'Credential and NoAuthentication cannot be used together.'
        $errorRecordParameters = @{
            Exception    = [System.ArgumentException]::new($message)
            Category     = 'InvalidArgument'
            ErrorId      = 'HomebridgeAuthenticationModeConflict'
            TargetObject = $InstanceName
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

    if ($PSBoundParameters.ContainsKey('Credential')) {
        $plainPassword = $Credential.GetNetworkCredential().Password

        if ($plainPassword -eq '********') {
            $message = 'The redacted password placeholder cannot be saved as a password.'
            $errorRecordParameters = @{
                Exception         = [System.ArgumentException]::new($message)
                Category          = 'InvalidArgument'
                ErrorId           = 'HomebridgeConfigurationRedactedPasswordRejected'
                TargetObject      = $InstanceName
                Activity          = $MyInvocation.MyCommand.Name
                RecommendedAction = 'Supply the actual Homebridge password in Credential.'
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
    }

    if (-not $connectionExists) {
        $missingParameters = @('Url').Where({ -not $PSBoundParameters.ContainsKey($_) })
        if (-not $PSBoundParameters.ContainsKey('Credential') -and -not $NoAuthentication) {
            $missingParameters += 'Credential or NoAuthentication'
        }

        if ($missingParameters.Count -gt 0) {
            $message = "A new Homebridge connection requires these parameters: $($missingParameters -join ', ')."
            $errorRecordParameters = @{
                Exception    = [System.ArgumentException]::new($message)
                Category     = 'InvalidArgument'
                ErrorId      = 'HomebridgeConfigurationRequiredParameterMissing'
                TargetObject = $InstanceName
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
    }

    $existingConnection = if ($connectionExists) {
        $configuration.Connections[$InstanceName]
    }
    else {
        $null
    }

    $resolvedUrl = if ($PSBoundParameters.ContainsKey('Url')) {
        $Url.TrimEnd('/')
    }
    else {
        $existingConnection.Url
    }

    if ($NoAuthentication) {
        $resolvedAuthentication = 'None'
        $resolvedUsername = $null
    }
    elseif ($PSBoundParameters.ContainsKey('Credential')) {
        $resolvedAuthentication = 'Credential'
        $resolvedUsername = $Credential.UserName
    }
    else {
        $resolvedAuthentication = $existingConnection.Authentication
        $resolvedUsername = $existingConnection.Username
    }

    $existingEncryptionMode = if ($connectionExists -and $existingConnection.Secret -is [System.Collections.IDictionary]) {
        $existingConnection.Secret.Mode
    }
    else {
        'None'
    }

    try {
        $changesToCredentialAuthentication = $false

        if ($connectionExists -and $PSBoundParameters.ContainsKey('Credential')) {
            $changesToCredentialAuthentication = $existingConnection.Authentication -ne 'Credential'
        }

        $resolvedEncryptionMode = if ($PSBoundParameters.ContainsKey('EncryptionMode')) {
            Resolve-PSHomebridgeEncryptionMode -EncryptionMode $EncryptionMode
        }
        elseif (-not $connectionExists -or $changesToCredentialAuthentication) {
            Resolve-PSHomebridgeEncryptionMode
        }
        else {
            $existingEncryptionMode
        }

        if ($resolvedAuthentication -eq 'None') {
            $protectedPassword = $null
            $resolvedEncryptionMode = 'None'
        }
        elseif ($PSBoundParameters.ContainsKey('Credential')) {
            $protectedPassword = Protect-PSHomebridgeConfigurationSecret -Secret $plainPassword -EncryptionMode $resolvedEncryptionMode
        }
        elseif ($PSBoundParameters.ContainsKey('EncryptionMode')) {
            $plainPassword = Unprotect-PSHomebridgeConfigurationSecret -Value $existingConnection.Secret
            $protectedPassword = Protect-PSHomebridgeConfigurationSecret -Secret $plainPassword -EncryptionMode $resolvedEncryptionMode
        }
        else {
            $protectedPassword = $existingConnection.Secret
        }
    }
    catch {
        $sensitiveTextParameters = @{
            Text           = "Unable to protect the password for Homebridge connection '$InstanceName'. $($_.Exception.Message)"
            SensitiveValue = @($plainPassword)
        }
        $message = Protect-PSHomebridgeSensitiveText @sensitiveTextParameters
        $exception = [System.Security.Cryptography.CryptographicException]::new($message, $_.Exception)

        $errorRecordParameters = @{
            Exception    = $exception
            Category     = 'SecurityError'
            ErrorId      = 'HomebridgeConfigurationEncryptionFailed'
            TargetObject = $InstanceName
            Activity     = $MyInvocation.MyCommand.Name
        }
        $errorRecord = New-PSHomebridgeErrorRecord @errorRecordParameters

        $errorHandlerParameters = @{
            Cmdlet              = $PSCmdlet
            ErrorRecord         = $errorRecord
            OriginalErrorAction = $originalErrorAction
            LogMessage          = $message
            SensitiveValue      = @($plainPassword)
        }
        Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
        return
    }

    # Keep the identity stable so one cache entry always belongs to one saved connection.
    $connectionId = if ($connectionExists) {
        $existingConnection.ConnectionId
    }
    else {
        [System.Guid]::NewGuid().ToString('N')
    }

    $configuration.Connections[$InstanceName] = [ordered]@{
        Url            = $resolvedUrl
        Authentication = $resolvedAuthentication
        Username       = $resolvedUsername
        Secret         = $protectedPassword
        ConnectionId   = $connectionId
    }

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
        $sensitiveTextParameters = @{
            Text           = "Unable to save Homebridge connection '$InstanceName'. $($_.Exception.Message)"
            SensitiveValue = @($plainPassword)
        }
        $message = Protect-PSHomebridgeSensitiveText @sensitiveTextParameters
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
            SensitiveValue      = @($plainPassword)
        }
        Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
        return
    }

    # Any saved change can make the retained authorization invalid.
    [void] $script:HomebridgeAccessTokens.Remove($connectionId)
    $redactedPassword = if ($resolvedAuthentication -eq 'Credential') {
        '********'
    }
    else {
        $null
    }

    $outputConnection = [PSCustomObject]@{
        InstanceName   = $InstanceName
        Url            = $resolvedUrl
        Authentication = $resolvedAuthentication
        Username       = $resolvedUsername
        Password       = $redactedPassword
        EncryptionMode = $resolvedEncryptionMode
    }
    $outputConnection.PSObject.TypeNames.Insert(0, 'PSHomebridge.Connection')
    $outputConnection
}
