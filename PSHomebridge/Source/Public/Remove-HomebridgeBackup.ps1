function Remove-HomebridgeBackup {
    <#
    .SYNOPSIS
        Removes a scheduled Homebridge backup.

    .DESCRIPTION
        This function permanently removes one scheduled backup from the Homebridge instance. It supports ShouldProcess and uses high confirmation impact.

    .PARAMETER InstanceName
        The saved connection name.

    .PARAMETER Url
        An explicit Homebridge URL.

    .PARAMETER Credential
        Explicit credentials.

    .PARAMETER NoAuthentication
        Indicates authentication is disabled.

    .PARAMETER BackupId
        The scheduled backup identifier.

    .EXAMPLE
        Remove-HomebridgeBackup -InstanceName home -BackupId backup-1

        Removes backup-1 after confirmation.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        None.

        This function does not return objects.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Named')]
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
        [ValidateNotNullOrEmpty()]
        [System.String]
        $BackupId
    )

    if (-not $PSCmdlet.ShouldProcess($BackupId, 'Remove scheduled Homebridge backup')) {
        return
    }

    $escapedBackupId = [System.Uri]::EscapeDataString($BackupId)
    $request = @{
        Method  = 'DELETE'
        Path    = "/api/backup/scheduled-backups/$escapedBackupId"
        Confirm = $false
    }

    foreach ($key in @('InstanceName', 'Url', 'Credential', 'NoAuthentication')) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $request[$key] = $PSBoundParameters[$key]
        }
    }

    $null = Invoke-HomebridgeApiRequest @request
}
