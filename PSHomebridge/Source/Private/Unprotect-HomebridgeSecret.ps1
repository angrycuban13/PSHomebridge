function Unprotect-HomebridgeSecret {
    <#
    .SYNOPSIS
        Unprotects a connection secret.
    .DESCRIPTION
        This function restores a SecureString from a supported secret envelope.
    .PARAMETER Value
        The persisted secret envelope.
    .EXAMPLE
        Unprotect-HomebridgeSecret -Value $record.Secret
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.Security.SecureString. This function returns a secure value.
    #>
    [CmdletBinding()]
    [OutputType([System.Security.SecureString])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Value
    )

    if ($Value -is [System.String]) {
        return ConvertTo-SecureString -String $Value -AsPlainText -Force
    }

    if ($Value -isnot [System.Collections.IDictionary]) {
        throw 'The saved Homebridge password has an invalid format.'
    }

    switch ($Value.Mode) {
        'Dpapi' { ConvertTo-SecureString -String $Value.CipherText -ErrorAction Stop }
        'Aes256' { ConvertTo-SecureString -String $Value.CipherText -Key (Get-HomebridgeAesKey) -ErrorAction Stop }
        default { throw "Unsupported secret protection mode '$($Value.Mode)'." }
    }
}
