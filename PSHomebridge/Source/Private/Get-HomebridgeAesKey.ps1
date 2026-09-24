function Get-HomebridgeAesKey {
    <#
    .SYNOPSIS
        Gets the portable encryption key.
    .DESCRIPTION
        This function validates and returns the external 32-byte AES key.
    .EXAMPLE
        Get-HomebridgeAesKey
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.Byte[]. This function returns a 32-byte key.
    #>
    [CmdletBinding()]
    [OutputType([System.Byte[]])]
    param ()

    $encodedKey = [System.Environment]::GetEnvironmentVariable('PSHOMEBRIDGE_AES_KEY')

    if ([System.String]::IsNullOrWhiteSpace($encodedKey)) {
        throw 'AES-256 encryption requires PSHOMEBRIDGE_AES_KEY.'
    }

    try {
        $key = [System.Convert]::FromBase64String($encodedKey)
    }
    catch {
        throw 'PSHOMEBRIDGE_AES_KEY must be valid Base64.'
    }

    if ($key.Length -ne 32) {
        throw 'PSHOMEBRIDGE_AES_KEY must decode to exactly 32 bytes.'
    }

    $key
}
