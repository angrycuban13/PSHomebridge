function Protect-HomebridgeSecret {
    <#
    .SYNOPSIS
        Protects a connection secret.
    .DESCRIPTION
        This function creates a versioned DPAPI or AES-256 envelope, or returns explicit plaintext.
    .PARAMETER SecureString
        The secure value to protect.
    .PARAMETER EncryptionMode
        The protection mechanism.
    .EXAMPLE
        Protect-HomebridgeSecret -SecureString $credential.Password -EncryptionMode Dpapi
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.Collections.Hashtable. This function returns a protected envelope.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]
        $SecureString,

        [Parameter(Mandatory = $true)]
        [ValidateSet('None', 'Dpapi', 'Aes256')]
        [System.String]
        $EncryptionMode
    )

    switch ($EncryptionMode) {
        'Dpapi' {
            if (-not $IsWindows) {
                throw 'DPAPI protection is available only on Windows.'
            }

            $cipherText = ConvertFrom-SecureString -SecureString $SecureString -ErrorAction Stop
        }
        'Aes256' {
            $cipherText = ConvertFrom-SecureString -SecureString $SecureString -Key (Get-HomebridgeAesKey) -ErrorAction Stop
        }
        'None' { return [System.Net.NetworkCredential]::new('', $SecureString).Password }
    }

    @{
        Version    = 1
        Mode       = $EncryptionMode
        CipherText = $cipherText
    }
}
