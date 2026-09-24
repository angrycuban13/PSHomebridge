function Invoke-HomebridgeApiRequest {
    <#
    .SYNOPSIS
        Sends an authenticated Homebridge API request.
    .DESCRIPTION
        This function resolves a connection, applies its bearer token, invokes HTTP, and retries authentication once when rejected.
    .PARAMETER Name
        The saved connection name.
    .PARAMETER Url
        An explicit Homebridge base URL.
    .PARAMETER Credential
        Explicit Homebridge credentials.
    .PARAMETER NoAuthentication
        Indicates authentication is disabled.
    .PARAMETER Method
        The HTTP method.
    .PARAMETER Path
        A relative path beginning with /api/.
    .PARAMETER Query
        Query values to serialize.
    .PARAMETER Body
        An optional JSON request body.
    .PARAMETER OutFile
        An optional response file path.
    .EXAMPLE
        Invoke-HomebridgeApiRequest -Name home -Method GET -Path '/api/plugins'
    .EXAMPLE
        Invoke-HomebridgeApiRequest -Url 'https://homebridge.test' -Credential $credential -Method GET -Path '/api/plugins'
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.Object. This function returns the upstream response or writes OutFile.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Named')]
    [OutputType([System.Object])]
    param (
        [Parameter(ParameterSetName = 'Named')]
        [Alias('ConnectionName')]
        [ValidatePattern('.*\S.*')]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitCredential')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitNoAuthentication')]
        [ValidateScript({ Test-HomebridgeUrl -Url $_ })]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitNoAuthentication')]
        [System.Management.Automation.SwitchParameter]
        $NoAuthentication,

        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [System.String]
        $Method,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^/api(?:/|$)')]
        [System.String]
        $Path,

        [Parameter()]
        [System.Collections.IDictionary]
        $Query,

        [Parameter()]
        [System.Object]
        $Body,

        [Parameter()]
        [System.String]
        $OutFile
    )

    $originalErrorAction = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        [System.Management.Automation.ActionPreference] $PSBoundParameters.ErrorAction
    }
    else {
        [System.Management.Automation.ActionPreference] $ErrorActionPreference
    }
    $ErrorActionPreference = 'Stop'

    $resolveParameters = @{}
    foreach ($key in @('Name', 'Url', 'Credential', 'NoAuthentication')) {
        if ($PSBoundParameters.ContainsKey($key)) { $resolveParameters[$key] = $PSBoundParameters[$key] }
    }

    $connection = Resolve-HomebridgeConnection @resolveParameters
    $requestUri = "$($connection.Url)$Path"

    $changesState = $Method -ne 'GET' -or $PSBoundParameters.ContainsKey('OutFile')
    if ($changesState -and -not $PSCmdlet.ShouldProcess($requestUri, "$Method Homebridge API request")) {
        return
    }

    if ($null -ne $Query) {
        $parts = foreach ($key in @($Query.Keys | Sort-Object)) {
            foreach ($value in @($Query[$key])) {
                if ($null -ne $value) {
                    '{0}={1}' -f [System.Uri]::EscapeDataString([System.String] $key), [System.Uri]::EscapeDataString([System.String] $value)
                }
            }
        }
        if (@($parts).Count -gt 0) { $requestUri += '?' + ($parts -join '&') }
    }

    for ($attempt = 0; $attempt -lt 2; $attempt++) {
        $token = Get-HomebridgeAccessToken -Connection $connection
        $parameters = @{
            Uri         = $requestUri
            Method      = $Method
            Headers     = @{ Authorization = "Bearer $token" }
            ErrorAction = 'Stop'
        }

        if ($PSBoundParameters.ContainsKey('Body')) {
            $parameters.ContentType = 'application/json'
            $parameters.Body = if ($Body -is [System.String]) { $Body } else { $Body | ConvertTo-Json -Depth 20 }
        }
        if ($PSBoundParameters.ContainsKey('OutFile')) { $parameters.OutFile = $OutFile }

        try {
            $response = Invoke-HomebridgeHttpRequest -Parameters $parameters

            if (-not $connection.Cacheable) {
                Clear-HomebridgeAccessToken -Connection $connection
            }

            return $response
        }
        catch {
            $statusCode = if ($null -ne $_.Exception.PSObject.Properties['StatusCode'] -and $null -ne $_.Exception.StatusCode) {
                [System.Int32] $_.Exception.StatusCode
            }
            elseif ($null -ne $_.Exception.Response) {
                [System.Int32] $_.Exception.Response.StatusCode
            }
            else {
                0
            }
            $authenticationRejected = $statusCode -in @(401, 403)

            if ($authenticationRejected -and $attempt -eq 0) {
                Clear-HomebridgeAccessToken -Connection $connection
                continue
            }

            $message = Protect-HomebridgeErrorMessage -Message $_.Exception.Message -Secret @($token)
            $exception = [System.Net.Http.HttpRequestException]::new("Homebridge API $Method request to '$requestUri' failed. $message", $_.Exception)
            $errorRecord = New-HomebridgeErrorRecord -Exception $exception -Category ConnectionError -ErrorId 'HomebridgeApiRequestFailed' -TargetObject $requestUri -Activity $MyInvocation.MyCommand.Name

            if (-not $connection.Cacheable) {
                Clear-HomebridgeAccessToken -Connection $connection
            }

            Invoke-HomebridgeErrorHandler -Cmdlet $PSCmdlet -ErrorRecord $errorRecord -OriginalErrorAction $originalErrorAction
            return
        }
    }

    if (-not $connection.Cacheable) { Clear-HomebridgeAccessToken -Connection $connection }
}
