function Resolve-HomebridgeDownloadPath {
    <#
    .SYNOPSIS
        Resolves a backup download destination.
    .DESCRIPTION
        This function returns an absolute file path and rejects directory destinations.
    .PARAMETER Path
        The requested destination path.
    .EXAMPLE
        Resolve-HomebridgeDownloadPath -Path './backup.tar.gz'
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.String. This function returns an absolute path.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    if (Test-Path -LiteralPath $resolved -PathType Container) { throw "OutFile '$resolved' is a directory." }
    $resolved
}
