function New-HomebridgeErrorRecord {
    <#
    .SYNOPSIS
        Creates a structured PSHomebridge error.
    .DESCRIPTION
        This function creates an ErrorRecord with stable metadata.
    .PARAMETER Exception
        The underlying exception.
    .PARAMETER Category
        The PowerShell error category.
    .PARAMETER ErrorId
        The stable error identifier.
    .PARAMETER TargetObject
        The failed target.
    .PARAMETER Activity
        The operation that failed.
    .PARAMETER RecommendedAction
        Suggested remediation.
    .EXAMPLE
        New-HomebridgeErrorRecord -Exception $exception -Category InvalidOperation -ErrorId HomebridgeFailure
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.Management.Automation.ErrorRecord. This function returns a structured error.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This function creates an in-memory error record and does not change system state.')]
    [CmdletBinding(SupportsShouldProcess = $false)]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Exception]
        $Exception,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorCategory]
        $Category,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ErrorId,

        [Parameter()]
        [AllowNull()]
        [System.Object]
        $TargetObject,

        [Parameter()]
        [System.String]
        $Activity,

        [Parameter()]
        [System.String]
        $RecommendedAction
    )

    $record = [System.Management.Automation.ErrorRecord]::new($Exception, $ErrorId, $Category, $TargetObject)
    if ($PSBoundParameters.ContainsKey('Activity')) { $record.CategoryInfo.Activity = $Activity }
    if ($PSBoundParameters.ContainsKey('RecommendedAction')) {
        $record.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($Exception.Message)
        $record.ErrorDetails.RecommendedAction = $RecommendedAction
    }
    $record
}
