function Get-PSHomebridgeAesKey {
    <#
    .SYNOPSIS
        Retrieves the PSHomebridge AES-256 configuration key.

    .DESCRIPTION
        This function reads and validates the separately supplied PSHOMEBRIDGE_AES_KEY environment variable.

    .EXAMPLE
        Get-PSHomebridgeAesKey

        Returns the validated AES-256 key from PSHOMEBRIDGE_AES_KEY.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        [System.Byte[]]

        This function returns a 32-byte AES key.
    #>
    [CmdletBinding()]
    [OutputType([System.Byte[]])]
    param()

    $encodedKey = [System.Environment]::GetEnvironmentVariable('PSHOMEBRIDGE_AES_KEY')

    if ([System.String]::IsNullOrWhiteSpace($encodedKey)) {
        throw 'AES-256 configuration encryption requires the PSHOMEBRIDGE_AES_KEY environment variable.'
    }

    try {
        $key = [System.Convert]::FromBase64String($encodedKey)
    }
    catch {
        throw 'PSHOMEBRIDGE_AES_KEY must be a valid Base64-encoded value.'
    }

    if ($key.Length -ne 32) {
        throw 'PSHOMEBRIDGE_AES_KEY must decode to exactly 32 bytes.'
    }

    [System.Byte[]] $key
}
