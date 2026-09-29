function Save-HomebridgeBackup {
    <#
    .SYNOPSIS
        Downloads a scheduled Homebridge backup.

    .DESCRIPTION
        This function saves a current instance backup or one scheduled backup to an explicit local path. It creates a missing parent directory and returns the saved file.

        It rejects a directory destination. It also rejects an existing file unless the caller sets Force. The operation supports ShouldProcess.

    .PARAMETER InstanceName
        The saved connection name.

    .PARAMETER Url
        An explicit Homebridge URL.

    .PARAMETER Credential
        Explicit credentials.

    .PARAMETER NoAuthentication
        Indicates that the server does not require authentication.

    .PARAMETER BackupId
        The scheduled backup identifier. When omitted, the function downloads a current instance backup.

    .PARAMETER OutFile
        The explicit local destination.

    .PARAMETER Force
        Permits replacing an existing destination file.

    .EXAMPLE
        Save-HomebridgeBackup -InstanceName home -BackupId backup-1 -OutFile './backup.tar.gz'

        Saves backup-1 at the requested destination and returns the saved file.

    .EXAMPLE
        Save-HomebridgeBackup -InstanceName home -OutFile './homebridge-current.tar.gz'

        Creates and saves a current backup of the instance.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        System.IO.FileInfo.

        This function returns the completed download file.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Named')]
    [OutputType([System.IO.FileInfo])]
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

    if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $PSBoundParameters.ErrorAction
    }
    else {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $ErrorActionPreference
    }

    $ErrorActionPreference = 'Stop'

    $destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)

    if (Test-Path -LiteralPath $destination -PathType Container) {
        $message = "OutFile '$destination' is a directory."
        $exception = [System.ArgumentException]::new($message, 'OutFile')
        $errorRecordParameters = @{
            Exception         = $exception
            Category          = 'InvalidArgument'
            ErrorId           = 'HomebridgeBackupDestinationIsDirectory'
            TargetObject      = $destination
            Activity          = $MyInvocation.MyCommand.Name
            RecommendedAction = 'Specify a file path for OutFile.'
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

    if ((Test-Path -LiteralPath $destination -PathType Leaf) -and -not $Force) {
        $message = "OutFile '$destination' already exists."
        $exception = [System.IO.IOException]::new($message)
        $errorRecordParameters = @{
            Exception         = $exception
            Category          = 'ResourceExists'
            ErrorId           = 'HomebridgeBackupDestinationExists'
            TargetObject      = $destination
            Activity          = $MyInvocation.MyCommand.Name
            RecommendedAction = 'Specify a different path or use Force to replace the file.'
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

    $backupDescription = if ($PSBoundParameters.ContainsKey('BackupId')) {
        "scheduled Homebridge backup '$BackupId'"
    }
    else {
        'current Homebridge instance backup'
    }

    if (-not $PSCmdlet.ShouldProcess($destination, "Download $backupDescription")) {
        return
    }

    $directory = Split-Path -Parent $destination

    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    # Keep an incomplete download outside the final path.
    $temporaryPath = Join-Path $directory ".$([System.IO.Path]::GetFileName($destination)).$([System.Guid]::NewGuid().ToString('N')).tmp"
    $path = if ($PSBoundParameters.ContainsKey('BackupId')) {
        $escapedBackupId = [System.Uri]::EscapeDataString($BackupId)
        "/api/backup/scheduled-backups/$escapedBackupId"
    }
    else {
        '/api/backup/download'
    }

    $request = @{
        Method  = 'GET'
        Path    = $path
        OutFile = $temporaryPath
        Confirm = $false
    }

    foreach ($key in @('InstanceName', 'Url', 'Credential', 'NoAuthentication')) {
        if ($PSBoundParameters.ContainsKey($key)) {
            $request[$key] = $PSBoundParameters[$key]
        }
    }

    try {
        $null = Invoke-HomebridgeApiRequest @request
        $moveParameters = @{
            LiteralPath = $temporaryPath
            Destination = $destination
            Force       = $Force
            ErrorAction = 'Stop'
        }
        Move-Item @moveParameters
        Get-Item -LiteralPath $destination
    }
    finally {
        # Remove the incomplete file after a failed request or move.
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}
