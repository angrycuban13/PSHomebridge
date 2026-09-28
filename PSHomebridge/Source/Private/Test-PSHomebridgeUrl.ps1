function Test-PSHomebridgeUrl {
    <#
    .SYNOPSIS
        Validates a Homebridge instance URL.

    .DESCRIPTION
        This function returns true for an absolute HTTP or HTTPS URL that contains a host. It reports a validation error for all other values.

    .PARAMETER Url
        The absolute URL to validate.

    .EXAMPLE
        Test-PSHomebridgeUrl -Url 'http://localhost:7878'

        Returns true because the value is an absolute HTTP URL with a host.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        [System.Boolean]

        This function returns a Boolean indicating whether the value is valid.
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Url
    )

    $uri = $null

    if (-not [uri]::TryCreate($Url, [UriKind]::Absolute, [ref] $uri)) {
        throw 'Url must be an absolute URL.'
    }

    if ($uri.Scheme -notin 'http', 'https') {
        throw 'Url must use HTTP or HTTPS.'
    }

    if ([string]::IsNullOrWhiteSpace($uri.Host)) {
        throw 'Url must include a host.'
    }

    $true
}
