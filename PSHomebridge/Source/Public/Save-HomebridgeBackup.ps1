function Save-HomebridgeBackup {
    <#
    .SYNOPSIS
        Downloads a scheduled Homebridge backup.
    .DESCRIPTION
        This function downloads to a temporary sibling and atomically places the completed file at the explicit destination.
    .PARAMETER Name
        The saved connection name.
    .PARAMETER Url
        An explicit Homebridge URL.
    .PARAMETER Credential
        Explicit credentials.
    .PARAMETER NoAuthentication
        Indicates authentication is disabled.
    .PARAMETER BackupId
        The scheduled backup identifier.
    .PARAMETER OutFile
        The explicit local destination.
    .PARAMETER Force
        Permits replacing an existing destination file.
    .EXAMPLE
        Save-HomebridgeBackup -Name home -BackupId backup-1 -OutFile './backup.tar.gz'
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.IO.FileInfo. This function returns the completed download file.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Named')]
    [OutputType([System.IO.FileInfo])]
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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $BackupId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OutFile,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    $destination = Resolve-HomebridgeDownloadPath -Path $OutFile
    if ((Test-Path -LiteralPath $destination -PathType Leaf) -and -not $Force) { throw "OutFile '$destination' already exists. Use Force to replace it." }
    if (-not $PSCmdlet.ShouldProcess($destination, "Download Homebridge backup '$BackupId'")) { return }

    $directory = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) { $null = New-Item -ItemType Directory -Path $directory -Force }
    $temporaryPath = Join-Path $directory ".$([System.IO.Path]::GetFileName($destination)).$([System.Guid]::NewGuid().ToString('N')).tmp"
    $escapedBackupId = [System.Uri]::EscapeDataString($BackupId)
    $request = @{ Method = 'GET'; Path = "/api/backup/scheduled-backups/$escapedBackupId"; OutFile = $temporaryPath; Confirm = $false }
    foreach ($key in @('Name', 'Url', 'Credential', 'NoAuthentication')) { if ($PSBoundParameters.ContainsKey($key)) { $request[$key] = $PSBoundParameters[$key] } }

    try {
        $null = Invoke-HomebridgeApiRequest @request
        Move-Item -LiteralPath $temporaryPath -Destination $destination -Force:$Force -ErrorAction Stop
        Get-Item -LiteralPath $destination
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) { Remove-Item -LiteralPath $temporaryPath -Force }
    }
}
