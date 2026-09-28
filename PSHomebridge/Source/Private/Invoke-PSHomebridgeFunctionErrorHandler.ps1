function Invoke-PSHomebridgeFunctionErrorHandler {
    <#
    .SYNOPSIS
        Emits a sanitized error according to the caller's effective error action.

    .DESCRIPTION
        This function removes supplied secrets from an error. It logs the error unless the environment disables logging, then applies the caller's error action.

        A logging failure produces a warning and does not replace the original error.

    .PARAMETER Cmdlet
        The calling function's PSCmdlet object.

    .PARAMETER ErrorRecord
        The PowerShell error record to format or emit.

    .PARAMETER OriginalErrorAction
        The caller's effective error action before internal normalization.

    .PARAMETER LogMessage
        A human-readable summary written before detailed error information.

    .PARAMETER LogEntryParameters
        Additional safe parameters supplied to the logging function.

    .PARAMETER SensitiveValue
        Values replaced with the redaction marker.

    .PARAMETER NoLog
        Prevents expected errors from being written to the log.

    .EXAMPLE
        Invoke-PSHomebridgeFunctionErrorHandler -Cmdlet $PSCmdlet -ErrorRecord $_ -OriginalErrorAction $originalErrorAction

        Logs and emits the supplied operational error according to the caller's error action.

    .EXAMPLE
        Invoke-PSHomebridgeFunctionErrorHandler -Cmdlet $PSCmdlet -ErrorRecord $errorRecord -OriginalErrorAction $originalErrorAction -NoLog

        Emits an expected error without writing it to the operational log.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        None.

        This function does not return objects to the pipeline.
    #>
    [CmdletBinding()]
    [OutputType([System.Void])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord,

        [Parameter(Mandatory)]
        [System.Management.Automation.ActionPreference]
        $OriginalErrorAction,

        [Parameter()]
        [System.String]
        $LogMessage,

        [Parameter()]
        [System.Collections.Hashtable]
        $LogEntryParameters = @{},

        [Parameter()]
        [System.String[]]
        $SensitiveValue,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoLog
    )

    if (-not $NoLog -and $env:PSHOMEBRIDGE_LOG_DISABLED -cne '1') {
        $summary = if ([System.String]::IsNullOrWhiteSpace($LogMessage)) {
            $ErrorRecord.Exception.Message
        }
        else {
            $LogMessage
        }

        $errorDetails = Resolve-PSHomebridgeErrorRecord -ErrorRecord $ErrorRecord

        $logText = if ($summary -eq $ErrorRecord.Exception.Message) {
            $errorDetails
        }
        else {
            "$summary`n$errorDetails"
        }

        $logText = Protect-PSHomebridgeSensitiveText -Text $logText -SensitiveValue $SensitiveValue

        $writeLogParameters = @{
            Message         = $logText
            Severity        = 'Error'
            NoConsoleOutput = $true
        }

        if (-not [System.String]::IsNullOrWhiteSpace($env:PSHOMEBRIDGE_LOG_DIRECTORY)) {
            $writeLogParameters.LogFileDirectory = $env:PSHOMEBRIDGE_LOG_DIRECTORY
        }

        foreach ($key in $LogEntryParameters.Keys) {
            if ($key -notin @('Message', 'Severity', 'NoConsoleOutput')) {
                $writeLogParameters[$key] = $LogEntryParameters[$key]
            }
        }

        try {
            Write-PSHomebridgeLogEntry @writeLogParameters -ErrorAction Stop
        }
        catch {
            # A logging failure must never replace the original operation's error.
            Write-Warning 'PSHomebridge could not write the operational error log.' -WarningAction Continue
        }
    }

    $ErrorActionPreference = $OriginalErrorAction

    switch ($OriginalErrorAction) {
        'Stop' {
            $Cmdlet.ThrowTerminatingError($ErrorRecord)
        }
        { $_ -in 'SilentlyContinue', 'Ignore' } {
            return
        }
        default {
            $Cmdlet.WriteError($ErrorRecord)
        }
    }
}
