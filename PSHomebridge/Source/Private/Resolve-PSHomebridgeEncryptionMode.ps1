function Resolve-PSHomebridgeEncryptionMode {
    <#
    .SYNOPSIS
        Resolves the configuration encryption mode for the current platform.

    .DESCRIPTION
        This function returns the requested storage mode. Without a request, it returns Dpapi on Windows and None on other platforms.

        It rejects Dpapi on platforms other than Windows.

    .PARAMETER EncryptionMode
        The requested configuration encryption mode.

    .EXAMPLE
        Resolve-PSHomebridgeEncryptionMode

        Returns the platform-default configuration encryption mode.

    .EXAMPLE
        Resolve-PSHomebridgeEncryptionMode -EncryptionMode Aes256

        Validates and returns the explicitly requested AES-256 mode.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        [System.String]

        This function returns the resolved encryption mode name.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('None', 'Dpapi', 'Aes256')]
        [System.String]
        $EncryptionMode
    )

    if ($PSBoundParameters.ContainsKey('EncryptionMode')) {
        if ($EncryptionMode -eq 'Dpapi' -and -not $IsWindows) {
            throw 'DPAPI configuration encryption is supported only on Windows.'
        }

        return $EncryptionMode
    }

    if ($IsWindows) {
        return 'Dpapi'
    }

    'None'
}
