function New-HomebridgeConnection {
    <#
    .SYNOPSIS
        Creates a named Homebridge connection.
    .DESCRIPTION
        This function saves a complete Homebridge connection with protected credentials.
    .PARAMETER Name
        The unique connection name.
    .PARAMETER Url
        The Homebridge base URL.
    .PARAMETER Credential
        The username and password used for authentication.
    .PARAMETER NoAuthentication
        Indicates that Homebridge authentication is disabled.
    .PARAMETER EncryptionMode
        The secret protection mode.
    .PARAMETER AllowPlaintext
        Explicitly permits plaintext password storage.
    .EXAMPLE
        New-HomebridgeConnection -Name home -Url 'https://homebridge.test' -Credential $credential
    .EXAMPLE
        New-HomebridgeConnection -Name lab -Url 'http://lab.test' -NoAuthentication
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        PSHomebridge.Connection. This function returns a redacted connection.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Credential')]
    [OutputType('PSHomebridge.Connection')]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidatePattern('.*\S.*')]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-HomebridgeUrl -Url $_ })]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true, ParameterSetName = 'Credential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true, ParameterSetName = 'NoAuthentication')]
        [System.Management.Automation.SwitchParameter]
        $NoAuthentication,

        [Parameter(ParameterSetName = 'Credential')]
        [ValidateSet('None', 'Dpapi', 'Aes256')]
        [System.String]
        $EncryptionMode = $(if ($IsWindows) { 'Dpapi' } else { 'Aes256' }),

        [Parameter(ParameterSetName = 'Credential')]
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

    if ($store.Connections.Contains($Name)) {
        throw "Homebridge connection '$Name' already exists."
    }

    if (-not $PSCmdlet.ShouldProcess($Name, 'Create Homebridge connection')) {
        return
    }

    if ($EncryptionMode -eq 'None' -and -not $AllowPlaintext) {
        throw 'Plaintext storage requires AllowPlaintext with EncryptionMode None.'
    }

    $resolvedCredential = $Credential
    $authentication = if ($NoAuthentication.IsPresent) { 'None' } else { 'Credential' }
    try {
        $secret = if ($authentication -eq 'Credential') {
            Protect-HomebridgeSecret -SecureString $resolvedCredential.Password -EncryptionMode $EncryptionMode
        }
        else {
            $null
        }
    }
    catch {
        $exception = [System.Security.Cryptography.CryptographicException]::new("Unable to protect the password for Homebridge connection '$Name'.", $_.Exception)
        $errorRecord = New-HomebridgeErrorRecord -Exception $exception -Category SecurityError -ErrorId 'HomebridgeConfigurationEncryptionFailed' -TargetObject $Name -Activity $MyInvocation.MyCommand.Name
        Invoke-HomebridgeErrorHandler -Cmdlet $PSCmdlet -ErrorRecord $errorRecord -OriginalErrorAction $originalErrorAction
        return
    }

    $record = [ordered]@{
        Url            = $Url.TrimEnd('/')
        Authentication = $authentication
        Username       = if ($null -ne $resolvedCredential) { $resolvedCredential.UserName } else { $null }
        Secret         = $secret
        ConnectionId   = [System.Guid]::NewGuid().ToString('N')
    }

    $store.Connections[$Name] = $record
    try {
        Export-Configuration -InputObject $store -CompanyName 'AngryCuban13' -Name 'PSHomebridge' -Scope User -AsHashtable
    }
    catch {
        $exception = [System.InvalidOperationException]::new("Unable to save Homebridge connection '$Name'.", $_.Exception)
        $errorRecord = New-HomebridgeErrorRecord -Exception $exception -Category WriteError -ErrorId 'HomebridgeConfigurationWriteFailed' -TargetObject $Name -Activity $MyInvocation.MyCommand.Name
        Invoke-HomebridgeErrorHandler -Cmdlet $PSCmdlet -ErrorRecord $errorRecord -OriginalErrorAction $originalErrorAction
        return
    }
    ConvertTo-HomebridgeConnectionOutput -Name $Name -Record $record
}
