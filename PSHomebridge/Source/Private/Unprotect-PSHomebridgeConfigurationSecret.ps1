function Unprotect-PSHomebridgeConfigurationSecret {
    <#
    .SYNOPSIS
        Resolves a persisted PSHomebridge configuration secret.

    .DESCRIPTION
        This function returns a saved secret as plaintext. It accepts legacy plaintext and version 1 DPAPI or AES-256 values.

        It rejects unsupported formats, versions, and modes. DPAPI values require Windows. AES-256 values require the original external key.

    .PARAMETER Value
        The persisted plaintext value or encrypted secret envelope.

    .EXAMPLE
        Unprotect-PSHomebridgeConfigurationSecret -Value 'legacy-value'

        Returns a legacy plaintext configuration secret unchanged.

    .EXAMPLE
        Unprotect-PSHomebridgeConfigurationSecret -Value $encryptedValue

        Decrypts a supported versioned configuration-secret envelope.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        [System.String]

        This function returns the decrypted secret as plaintext.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Value
    )

    if ($Value -is [System.String]) {
        return $Value
    }

    if ($Value -isnot [System.Collections.IDictionary]) {
        throw 'The saved Homebridge API key has an invalid format.'
    }

    if ($Value.Version -ne 1) {
        throw "The saved Homebridge API key uses unsupported encryption version '$($Value.Version)'."
    }

    if ([System.String]::IsNullOrWhiteSpace([System.String] $Value.CipherText)) {
        throw 'The saved Homebridge API key does not contain ciphertext.'
    }

    try {
        switch ($Value.Mode) {
            'Dpapi' {
                if (-not $IsWindows) {
                    throw 'DPAPI configuration encryption is supported only on Windows.'
                }

                $secureSecret = ConvertTo-SecureString -String $Value.CipherText -ErrorAction Stop
            }
            'Aes256' {
                $key = Get-PSHomebridgeAesKey
                $secureSecret = ConvertTo-SecureString -String $Value.CipherText -Key $key -ErrorAction Stop
            }
            default {
                throw "The saved Homebridge API key uses unsupported encryption mode '$($Value.Mode)'."
            }
        }

        $secretPointer = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureSecret)

        try {
            [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer)
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer)
        }
    }
    catch {
        throw [System.Security.Cryptography.CryptographicException]::new(
            'Unable to decrypt a saved Homebridge API key. Verify the encryption mode, user context, and AES key.',
            $_.Exception
        )
    }
}
