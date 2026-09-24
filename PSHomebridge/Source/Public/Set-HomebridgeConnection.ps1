function Set-HomebridgeConnection {
    <#
    .SYNOPSIS
        Updates a named Homebridge connection.
    .DESCRIPTION
        This function updates only supplied connection fields and invalidates its cached token.
    .PARAMETER Name
        The saved connection name.
    .PARAMETER Url
        A replacement base URL.
    .PARAMETER Credential
        Replacement credentials.
    .PARAMETER NoAuthentication
        Changes the connection to authentication-disabled mode.
    .PARAMETER EncryptionMode
        The replacement secret protection mode.
    .PARAMETER AllowPlaintext
        Explicitly permits plaintext password storage.
    .EXAMPLE
        Set-HomebridgeConnection -Name home -Url 'https://new-homebridge.test'
    .EXAMPLE
        Set-HomebridgeConnection -Name home -Credential $credential -EncryptionMode Aes256
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        PSHomebridge.Connection. This function returns the redacted updated connection.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType('PSHomebridge.Connection')]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidatePattern('.*\S.*')]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateScript({ Test-HomebridgeUrl -Url $_ })]
        [System.String]
        $Url,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoAuthentication,

        [Parameter()]
        [ValidateSet('None', 'Dpapi', 'Aes256')]
        [System.String]
        $EncryptionMode,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AllowPlaintext
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

    if ($NoAuthentication -and $PSBoundParameters.ContainsKey('Credential')) {
        throw 'Credential and NoAuthentication cannot be used together.'
    }

    if ($EncryptionMode -eq 'None' -and -not $AllowPlaintext) {
        throw 'Plaintext storage requires AllowPlaintext with EncryptionMode None.'
    }

    if (-not $PSCmdlet.ShouldProcess($Name, 'Update Homebridge connection')) {
        return
    }

    $record = $store.Connections[$Name]
    $oldConnectionId = $record.ConnectionId

    if ($PSBoundParameters.ContainsKey('Url')) { $record.Url = $Url.TrimEnd('/') }

    if ($NoAuthentication) {
        $record.Authentication = 'None'
        $record.Username = $null
        $record.Secret = $null
    }
    else {
        try {
            if ($PSBoundParameters.ContainsKey('Credential')) {
                $mode = if ($PSBoundParameters.ContainsKey('EncryptionMode')) { $EncryptionMode } elseif ($record.Secret -is [System.Collections.IDictionary]) { $record.Secret.Mode } elseif ($null -ne $record.Secret) { 'None' } elseif ($IsWindows) { 'Dpapi' } else { 'Aes256' }
                $record.Authentication = 'Credential'
                $record.Username = $Credential.UserName
                $record.Secret = Protect-HomebridgeSecret -SecureString $Credential.Password -EncryptionMode $mode
            }
            elseif ($PSBoundParameters.ContainsKey('EncryptionMode')) {
                if ($record.Authentication -ne 'Credential') { throw 'EncryptionMode applies only to credential connections.' }
                $securePassword = Unprotect-HomebridgeSecret -Value $record.Secret
                $record.Secret = Protect-HomebridgeSecret -SecureString $securePassword -EncryptionMode $EncryptionMode
            }
        }
        catch {
            $exception = [System.Security.Cryptography.CryptographicException]::new("Unable to protect the password for Homebridge connection '$Name'.", $_.Exception)
            $errorRecord = New-HomebridgeErrorRecord -Exception $exception -Category SecurityError -ErrorId 'HomebridgeConfigurationEncryptionFailed' -TargetObject $Name -Activity $MyInvocation.MyCommand.Name
            Invoke-HomebridgeErrorHandler -Cmdlet $PSCmdlet -ErrorRecord $errorRecord -OriginalErrorAction $originalErrorAction
            return
        }
    }

    $record.ConnectionId = [System.Guid]::NewGuid().ToString('N')
    try {
        Export-Configuration -InputObject $store -CompanyName 'AngryCuban13' -Name 'PSHomebridge' -Scope User -AsHashtable
    }
    catch {
        $exception = [System.InvalidOperationException]::new("Unable to save Homebridge connection '$Name'.", $_.Exception)
        $errorRecord = New-HomebridgeErrorRecord -Exception $exception -Category WriteError -ErrorId 'HomebridgeConfigurationWriteFailed' -TargetObject $Name -Activity $MyInvocation.MyCommand.Name
        Invoke-HomebridgeErrorHandler -Cmdlet $PSCmdlet -ErrorRecord $errorRecord -OriginalErrorAction $originalErrorAction
        return
    }
    $script:HomebridgeAccessTokens.Remove($oldConnectionId)
    ConvertTo-HomebridgeConnectionOutput -Name $Name -Record $record
}
