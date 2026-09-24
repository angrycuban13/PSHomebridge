function Invoke-HomebridgeHttpRequest {
    <#
    .SYNOPSIS
        Invokes the low-level Homebridge HTTP request.
    .DESCRIPTION
        This function is the module's only direct Invoke-RestMethod caller.
    .PARAMETER Parameters
        Parameters passed to Invoke-RestMethod.
    .EXAMPLE
        Invoke-HomebridgeHttpRequest -Parameters $parameters
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.Object. This function returns the HTTP response.
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Parameters
    )

    Invoke-RestMethod @Parameters
}
