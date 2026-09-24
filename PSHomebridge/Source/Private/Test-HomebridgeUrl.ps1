function Test-HomebridgeUrl {
    <#
    .SYNOPSIS
        Tests a Homebridge base URL.
    .DESCRIPTION
        This function returns true for absolute HTTP and HTTPS URLs.
    .PARAMETER Url
        The URL to test.
    .EXAMPLE
        Test-HomebridgeUrl -Url 'https://homebridge.example'
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.Boolean. This function returns whether the URL is valid.
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Url
    )

    $uri = $null
    $created = [System.Uri]::TryCreate($Url, [System.UriKind]::Absolute, [ref] $uri)

    $created -and $uri.Scheme -in @('http', 'https') -and -not [System.String]::IsNullOrWhiteSpace($uri.Host)
}
