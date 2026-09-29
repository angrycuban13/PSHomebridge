function New-HomebridgeBackup {
    <#
    .SYNOPSIS
        Creates a Homebridge backup.

    .DESCRIPTION
        This function creates a backup file in the Homebridge backup directory. It changes files on the Homebridge instance and supports ShouldProcess.

    .PARAMETER InstanceName
        The saved connection name.

    .PARAMETER Url
        An explicit Homebridge URL.

    .PARAMETER Credential
        Explicit credentials.

    .PARAMETER NoAuthentication
        Indicates that the server does not require authentication.

    .EXAMPLE
        New-HomebridgeBackup -InstanceName home

        Creates a backup in the configured backup directory of the saved instance.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        PSHomebridge.Backup.

        This function returns the backup result supplied by Homebridge.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Named')]
    [OutputType('PSHomebridge.Backup')]
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
        $NoAuthentication
    )

    if (-not $PSCmdlet.ShouldProcess('Homebridge backup directory', 'Create Homebridge backup')) {
        return
    }

    $request = @{
        Method  = 'POST'
        Path    = '/api/backup'
        Confirm = $false
    }

    foreach ($key in @('InstanceName', 'Url', 'Credential', 'NoAuthentication')) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $request[$key] = $PSBoundParameters[$key]
        }
    }

    $result = Invoke-HomebridgeApiRequest @request

    if ($null -ne $result) {
        $result.PSObject.TypeNames.Insert(0, 'PSHomebridge.Backup')
        $result
    }
}
