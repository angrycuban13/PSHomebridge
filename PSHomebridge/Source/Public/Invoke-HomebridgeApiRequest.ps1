function Invoke-HomebridgeApiRequest {
    <#
    .SYNOPSIS
        Sends an authenticated request to the Homebridge API.

    .DESCRIPTION
        This function sends a request through a saved or explicit connection. It returns the response or saves the response when the caller sets OutFile.

        Named connections can reuse authorization. Explicit connections do not retain authorization. Expired authorization causes one renewal attempt.

        Requests that change data and requests that write files support ShouldProcess. This function does not add resource-specific type names.

    .PARAMETER InstanceName
        The name of the saved Homebridge connection. When omitted, exactly one saved connection must exist.

    .PARAMETER Url
        The absolute base URL of the Homebridge instance.

    .PARAMETER Credential
        The username and password used to authenticate with Homebridge.

    .PARAMETER NoAuthentication
        Uses an instance that does not require a username or password. The function obtains the required authorization automatically.

    .PARAMETER Method
        The HTTP method used for the request.

    .PARAMETER Path
        The relative Homebridge API path beginning with `/api`.

    .PARAMETER Query
        Query-string keys and values appended to the request URL.

    .PARAMETER Body
        The request body. Non-string values are serialized as JSON.

    .PARAMETER OutFile
        The optional response destination for a download.

    .EXAMPLE
        Invoke-HomebridgeApiRequest -InstanceName 'Home' -Method GET -Path '/api/plugins'

        Uses the saved connection named Home and returns the installed-plugin response.

    .EXAMPLE
        Invoke-HomebridgeApiRequest -Url 'http://localhost:8581' -Credential $credential -Method GET -Path '/api/plugins'

        Uses an explicit URL and credential without saving either value.

    .INPUTS
        None.

        You cannot pipe objects to this function.

    .OUTPUTS
        [System.Object]

        This function returns response objects retrieved from the Homebridge API or writes a response to OutFile.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Named')]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = 'Named')]
        [ValidateNotNullOrWhiteSpace()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitCredential')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ExplicitNoAuthentication')]
        [ValidateScript({ Test-PSHomebridgeUrl -Url $_ })]
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

        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $Query,

        [Parameter(Mandatory = $false)]
        [System.Object]
        $Body,

        [Parameter(Mandatory = $false)]
        [System.String]
        $OutFile
    )

    if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $PSBoundParameters.ErrorAction
    }
    else {
        $originalErrorAction = [System.Management.Automation.ActionPreference] $ErrorActionPreference
    }

    $ErrorActionPreference = 'Stop'
    $cacheable = $false
    $cacheKey = $null
    $plainPassword = $null
    $authenticationParameters = $null

    if ($PSCmdlet.ParameterSetName -eq 'Named') {
        try {
            $configuration = Get-PSHomebridgeConfiguration
        }
        catch {
            $message = "Unable to load the saved Homebridge connection configuration. $($_.Exception.Message)"
            $exception = [System.InvalidOperationException]::new($message, $_.Exception)
            $errorRecordParameters = @{
                Exception    = $exception
                Category     = 'ReadError'
                ErrorId      = 'HomebridgeConfigurationReadFailed'
                TargetObject = $InstanceName
                Activity     = $MyInvocation.MyCommand.Name
            }
            $errorRecord = New-PSHomebridgeErrorRecord @errorRecordParameters

            $errorHandlerParameters = @{
                Cmdlet              = $PSCmdlet
                ErrorRecord         = $errorRecord
                OriginalErrorAction = $originalErrorAction
                LogMessage          = $message
            }
            Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
            return
        }

        if ($PSBoundParameters.ContainsKey('InstanceName')) {
            if (-not $configuration.Connections.Contains($InstanceName)) {
                $message = "Homebridge connection '$InstanceName' was not found."
                $errorRecordParameters = @{
                    Exception         = [System.Management.Automation.ItemNotFoundException]::new($message)
                    Category          = 'ObjectNotFound'
                    ErrorId           = 'HomebridgeConnectionNotFound'
                    TargetObject      = $InstanceName
                    Activity          = $MyInvocation.MyCommand.Name
                    RecommendedAction = 'Create the connection with Set-PSHomebridgeConnection or specify an existing connection name.'
                }
                $errorRecord = New-PSHomebridgeErrorRecord @errorRecordParameters

                $errorHandlerParameters = @{
                    Cmdlet              = $PSCmdlet
                    ErrorRecord         = $errorRecord
                    OriginalErrorAction = $originalErrorAction
                    NoLog               = $true
                }
                Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
                return
            }

            $instanceName = $InstanceName
        }
        else {
            $connectionNames = @($configuration.Connections.Keys | Sort-Object)

            if ($connectionNames.Count -eq 0) {
                $message = 'No Homebridge connections were found.'
                $errorRecordParameters = @{
                    Exception         = [System.Management.Automation.ItemNotFoundException]::new($message)
                    Category          = 'ObjectNotFound'
                    ErrorId           = 'HomebridgeConnectionNotFound'
                    Activity          = $MyInvocation.MyCommand.Name
                    RecommendedAction = 'Create a connection with Set-PSHomebridgeConnection.'
                }
                $errorRecord = New-PSHomebridgeErrorRecord @errorRecordParameters

                $errorHandlerParameters = @{
                    Cmdlet              = $PSCmdlet
                    ErrorRecord         = $errorRecord
                    OriginalErrorAction = $originalErrorAction
                    NoLog               = $true
                }
                Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
                return
            }

            if ($connectionNames.Count -gt 1) {
                $message = "Multiple Homebridge connections match this request: $($connectionNames -join ', '). Specify InstanceName."
                $errorRecordParameters = @{
                    Exception         = [System.InvalidOperationException]::new($message)
                    Category          = 'InvalidArgument'
                    ErrorId           = 'HomebridgeConnectionAmbiguous'
                    TargetObject      = $connectionNames
                    Activity          = $MyInvocation.MyCommand.Name
                    RecommendedAction = 'Specify the desired connection with InstanceName.'
                }
                $errorRecord = New-PSHomebridgeErrorRecord @errorRecordParameters

                $errorHandlerParameters = @{
                    Cmdlet              = $PSCmdlet
                    ErrorRecord         = $errorRecord
                    OriginalErrorAction = $originalErrorAction
                    NoLog               = $true
                }
                Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
                return
            }

            $instanceName = $connectionNames[0]
        }

        $connection = $configuration.Connections[$instanceName]
        $resolvedUrl = $connection.Url
        $authentication = $connection.Authentication
        $resolvedUsername = $connection.Username
        $plainPassword = $connection.Password
        $cacheKey = $connection.ConnectionId
        $cacheable = $true
    }
    else {
        $resolvedUrl = $Url.TrimEnd('/')

        if ($NoAuthentication) {
            $authentication = 'None'
            $resolvedUsername = $null
            $plainPassword = $null
        }
        else {
            $authentication = 'Credential'
            $resolvedUsername = $Credential.UserName
            $plainPassword = $Credential.GetNetworkCredential().Password
        }
    }

    $requestUri = "$resolvedUrl$Path"

    if ($null -ne $Query -and $Query.Count -gt 0) {
        $queryParts = foreach ($key in @($Query.Keys | Sort-Object)) {
            foreach ($value in @($Query[$key])) {
                if ($null -ne $value) {
                    "$([System.Uri]::EscapeDataString([System.String] $key))=$([System.Uri]::EscapeDataString([System.String] $value))"
                }
            }
        }

        if (@($queryParts).Count -gt 0) {
            $requestUri += '?' + ($queryParts -join '&')
        }
    }

    $changesState = $Method -ne 'GET' -or $PSBoundParameters.ContainsKey('OutFile')

    if ($changesState -and -not $PSCmdlet.ShouldProcess($requestUri, "$Method Homebridge API request")) {
        return
    }

    $token = $null

    try {
        for ($attempt = 0; $attempt -lt 2; $attempt++) {
            if ($cacheable -and $script:HomebridgeAccessTokens.ContainsKey($cacheKey)) {
                $token = $script:HomebridgeAccessTokens[$cacheKey]
            }

            if ([System.String]::IsNullOrWhiteSpace($token)) {
                $authenticationUri = if ($authentication -eq 'Credential') {
                    "$resolvedUrl/api/auth/login"
                }
                else {
                    "$resolvedUrl/api/auth/noauth"
                }

                $authenticationParameters = @{
                    Uri         = $authenticationUri
                    Method      = 'POST'
                    ErrorAction = $ErrorActionPreference
                    Verbose     = $VerbosePreference
                    Debug       = $DebugPreference
                }

                if ($authentication -eq 'Credential') {
                    $authenticationBody = @{
                        username = $resolvedUsername
                        password = $plainPassword
                    }
                    $authenticationParameters.ContentType = 'application/json'
                    $authenticationParameters.Body = $authenticationBody | ConvertTo-Json
                }

                $authenticationResponse = Invoke-RestMethod @authenticationParameters
                $authenticationParameters.Body = $null
                $token = [System.String] $authenticationResponse.access_token

                if ([System.String]::IsNullOrWhiteSpace($token)) {
                    throw 'The authentication response did not contain an access token.'
                }

                # Explicit connections must not add short-lived tokens to the named-connection cache.
                if ($cacheable) {
                    $script:HomebridgeAccessTokens[$cacheKey] = $token
                }
            }

            $requestParameters = @{
                Uri         = $requestUri
                Method      = $Method
                Headers     = @{
                    Authorization = "Bearer $token"
                }
                ErrorAction = $ErrorActionPreference
                Verbose     = $VerbosePreference
                Debug       = $DebugPreference
            }

            if ($PSBoundParameters.ContainsKey('Body')) {
                $requestParameters.ContentType = 'application/json'
                $requestParameters.Body = if ($Body -is [System.String]) {
                    $Body
                }
                else {
                    $Body | ConvertTo-Json -Depth 20
                }
            }

            if ($PSBoundParameters.ContainsKey('OutFile')) {
                $requestParameters.OutFile = $OutFile
            }

            Write-Verbose "Invoking $Method request to `"$requestUri`"."

            try {
                return Invoke-RestMethod @requestParameters
            }
            catch {
                $statusCode = if ($null -ne $_.Exception.PSObject.Properties['StatusCode'] -and $null -ne $_.Exception.StatusCode) {
                    [System.Int32] $_.Exception.StatusCode
                }
                elseif ($null -ne $_.Exception.PSObject.Properties['Response'] -and $null -ne $_.Exception.Response) {
                    [System.Int32] $_.Exception.Response.StatusCode
                }
                else {
                    0
                }

                # Renew authorization one time. A second authorization failure remains visible to the caller.
                if ($statusCode -in @(401, 403) -and $attempt -eq 0) {
                    if ($cacheable) {
                        [void] $script:HomebridgeAccessTokens.Remove($cacheKey)
                    }
                    $token = $null
                    continue
                }

                throw
            }
        }
    }
    catch {
        $detailParts = @($_.Exception.Message)
        if ($null -ne $_.ErrorDetails -and -not [System.String]::IsNullOrWhiteSpace($_.ErrorDetails.Message)) {
            $detailParts += $_.ErrorDetails.Message
        }
        $sensitiveValues = @($token, $plainPassword)
        $details = Protect-PSHomebridgeSensitiveText -Text ($detailParts -join ' ') -SensitiveValue $sensitiveValues
        $message = "Homebridge API $Method request to '$requestUri' failed. $($details.Trim())"
        $exception = [System.Net.Http.HttpRequestException]::new($message)
        $errorRecordParameters = @{
            Exception    = $exception
            Category     = 'ConnectionError'
            ErrorId      = 'HomebridgeApiRequestFailed'
            TargetObject = $requestUri
            Activity     = $MyInvocation.MyCommand.Name
        }
        $errorRecord = New-PSHomebridgeErrorRecord @errorRecordParameters

        $errorHandlerParameters = @{
            Cmdlet              = $PSCmdlet
            ErrorRecord         = $errorRecord
            OriginalErrorAction = $originalErrorAction
            LogMessage          = $message
            SensitiveValue      = $sensitiveValues
        }
        Invoke-PSHomebridgeFunctionErrorHandler @errorHandlerParameters
        return
    }
    finally {
        $plainPassword = $null
        if ($null -ne $authenticationParameters -and $authenticationParameters.ContainsKey('Body')) {
            $authenticationParameters.Body = $null
        }
    }
}
