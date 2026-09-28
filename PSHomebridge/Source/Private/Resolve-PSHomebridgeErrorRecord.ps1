function Resolve-PSHomebridgeErrorRecord {
    <#
    .SYNOPSIS
        Formats an error record as readable diagnostic text.

    .DESCRIPTION
        This function returns diagnostic text for an error record. The text includes up to five inner exceptions, the category, the identifier, and the stack trace.

    .PARAMETER ErrorRecord
        The PowerShell error record to format.

    .EXAMPLE
        Resolve-PSHomebridgeErrorRecord -ErrorRecord $_

        Formats the supplied error record as readable diagnostic text.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        [System.String]

        This function returns the resulting text.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    process {
        $lines = [System.Collections.Generic.List[System.String]]::new()

        $lines.Add("Exception    : [$($ErrorRecord.Exception.GetType().FullName)] $($ErrorRecord.Exception.Message)")

        $innerException = $ErrorRecord.Exception.InnerException
        $depth = 0

        while ($null -ne $innerException -and $depth -lt 5) {
            $lines.Add("  Inner[$depth]  : [$($innerException.GetType().FullName)] $($innerException.Message)")
            $innerException = $innerException.InnerException
            $depth++
        }

        $lines.Add("Category     : $($ErrorRecord.CategoryInfo.ToString())")
        $lines.Add("ErrorId      : $($ErrorRecord.FullyQualifiedErrorId)")

        if (-not [System.String]::IsNullOrWhiteSpace($ErrorRecord.ScriptStackTrace)) {
            $lines.Add("Stack Trace  :`n$($ErrorRecord.ScriptStackTrace)")
        }

        return $lines -join "`n"
    }
}
