function Get-HomebridgeBackup {
    <#
    .SYNOPSIS
        Gets scheduled Homebridge backups.
    .DESCRIPTION
        This function returns scheduled backup metadata or the next scheduled backup time.
    .PARAMETER Name
        The saved connection name.
    .PARAMETER Url
        An explicit Homebridge URL.
    .PARAMETER Credential
        Explicit credentials.
    .PARAMETER NoAuthentication
        Indicates authentication is disabled.
    .PARAMETER Next
        Returns the next scheduled backup information.
    .EXAMPLE
        Get-HomebridgeBackup -Name home
    .EXAMPLE
        Get-HomebridgeBackup -Name home -Next
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        PSHomebridge.Backup or PSHomebridge.BackupSchedule. This function returns complete backup objects.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Named')]
    [OutputType('PSHomebridge.Backup', 'PSHomebridge.BackupSchedule')]
    param (
        [Parameter(ParameterSetName = 'Named')]
        [ValidatePattern('.*\S.*')]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitCredential')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitNoAuthentication')]
        [ValidateScript({ Test-HomebridgeUrl -Url $_ })]
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
    $request = @{ Method = 'GET'; Path = $path }
    foreach ($key in @('Name', 'Url', 'Credential', 'NoAuthentication')) { if ($PSBoundParameters.ContainsKey($key)) { $request[$key] = $PSBoundParameters[$key] } }
    $typeName = if ($Next) { 'PSHomebridge.BackupSchedule' } else { 'PSHomebridge.Backup' }

    foreach ($backup in @(Invoke-HomebridgeApiRequest @request)) {
        if ($null -eq $backup) { continue }
        $backup.PSObject.TypeNames.Insert(0, $typeName)
        $backup
    }
}
