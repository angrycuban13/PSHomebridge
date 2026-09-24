function Invoke-HomebridgeErrorHandler {
    <#
    .SYNOPSIS
        Emits a structured PSHomebridge error.
    .DESCRIPTION
        This function honors the calling command's effective ErrorAction preference.
    .PARAMETER Cmdlet
        The calling cmdlet.
    .PARAMETER ErrorRecord
        The error to emit.
    .PARAMETER OriginalErrorAction
        The caller's effective ErrorAction.
    .EXAMPLE
        Invoke-HomebridgeErrorHandler -Cmdlet $PSCmdlet -ErrorRecord $record -OriginalErrorAction Stop
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        None. This function emits an error.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ActionPreference]
        $OriginalErrorAction
    )

    $ErrorActionPreference = $OriginalErrorAction
    switch ($OriginalErrorAction) {
        'Stop' { $Cmdlet.ThrowTerminatingError($ErrorRecord) }
        { $_ -in 'SilentlyContinue', 'Ignore' } { return }
        default { $Cmdlet.WriteError($ErrorRecord) }
    }
}
