function Get-HomebridgeBackup {
    <#
    .SYNOPSIS
        Gets scheduled Homebridge backups.

    .DESCRIPTION
        This function returns scheduled backup records, or the next scheduled backup when the caller sets Next.

        It does not create, download, or remove backups.

    .PARAMETER InstanceName
        The saved connection name.

    .PARAMETER Url
        An explicit Homebridge URL.

    .PARAMETER Credential
        Explicit credentials.

    .PARAMETER NoAuthentication
        Indicates that the server does not require authentication.

    .PARAMETER Next
        Returns the next scheduled backup information.

    .EXAMPLE
        Get-HomebridgeBackup -InstanceName home

        Returns all scheduled backups from the saved connection named home.

    .EXAMPLE
        Get-HomebridgeBackup -InstanceName home -Next

        Returns the next scheduled-backup time from the saved connection named home.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        PSHomebridge.Backup or PSHomebridge.BackupSchedule.

        This function returns complete backup objects.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Named')]
    [OutputType('PSHomebridge.Backup', 'PSHomebridge.BackupSchedule')]
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

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Next
    )

    $path = if ($Next) { '/api/backup/scheduled-backups/next' } else { '/api/backup/scheduled-backups' }

    $request = @{
        Method = 'GET'
        Path   = $path
    }

    foreach ($key in @('InstanceName', 'Url', 'Credential', 'NoAuthentication')) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $request[$key] = $PSBoundParameters[$key]
        }
    }

    $typeName = if ($Next) { 'PSHomebridge.BackupSchedule' } else { 'PSHomebridge.Backup' }

    foreach ($backup in (Invoke-HomebridgeApiRequest @request)) {
        if ($null -eq $backup) {
            continue
        }

        $backup.PSObject.TypeNames.Insert(0, $typeName)
        $backup
    }
}
