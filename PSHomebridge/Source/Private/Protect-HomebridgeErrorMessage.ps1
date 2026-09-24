function Protect-HomebridgeErrorMessage {
    <#
    .SYNOPSIS
        Redacts secrets from text.
    .DESCRIPTION
        This function replaces supplied secret values with a fixed marker.
    .PARAMETER Message
        The text to sanitize.
    .PARAMETER Secret
        Secret values to redact.
    .EXAMPLE
        Protect-HomebridgeErrorMessage -Message 'token-value' -Secret 'token-value'
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.String. This function returns sanitized text.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Message,

        [Parameter()]
        [AllowNull()]
        [System.String[]]
        $Secret
    )

    $result = $Message

    foreach ($value in @($Secret)) {
        if (-not [System.String]::IsNullOrEmpty($value)) {
            $result = $result -replace [System.Text.RegularExpressions.Regex]::Escape($value), '[REDACTED]'
        }
    }

    $result
}
