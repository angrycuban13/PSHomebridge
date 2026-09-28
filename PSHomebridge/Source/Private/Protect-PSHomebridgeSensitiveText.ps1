function Protect-PSHomebridgeSensitiveText {
    <#
    .SYNOPSIS
        Redacts sensitive values from text.

    .DESCRIPTION
        This function replaces each supplied secret in text with `[REDACTED]`. It returns null when the input text is null and does not change other text.

    .PARAMETER Text
        The text to sanitize.

    .PARAMETER SensitiveValue
        The sensitive values to redact.

    .EXAMPLE
        Protect-PSHomebridgeSensitiveText -Text 'Key=secret' -SensitiveValue 'secret'

        Replaces the supplied secret with the standard redaction marker.

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
        [AllowNull()]
        [System.String]
        $Text,

        [AllowNull()]
        [System.String[]]
        $SensitiveValue
    )

    if ($null -eq $Text) {
        return $null
    }

    $sanitized = $Text

    foreach ($value in @($SensitiveValue)) {
        if (-not [System.String]::IsNullOrEmpty($value)) {
            $sanitized = $sanitized.Replace($value, '[REDACTED]')
        }
    }

    $sanitized
}
