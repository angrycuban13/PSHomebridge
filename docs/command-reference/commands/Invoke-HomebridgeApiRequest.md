---
document type: cmdlet
Locale: en-US
Module Name: PSHomebridge
PlatyPS schema version: 2024-05-01
title: Invoke-HomebridgeApiRequest
---
<!-- markdownlint-disable -->

# Invoke-HomebridgeApiRequest

## SYNOPSIS

Sends an authenticated request to the Homebridge API.

## SYNTAX

### Named (Default)

```
Invoke-HomebridgeApiRequest -Method <string> -Path <string> [-InstanceName <string>]
 [-Query <hashtable>] [-Body <Object>] [-OutFile <string>] [-WhatIf] [-Confirm]
```

### ExplicitNoAuthentication

```
Invoke-HomebridgeApiRequest -Url <string> -NoAuthentication -Method <string> -Path <string>
 [-Query <hashtable>] [-Body <Object>] [-OutFile <string>] [-WhatIf] [-Confirm]
```

### ExplicitCredential

```
Invoke-HomebridgeApiRequest -Url <string> -Credential <pscredential> -Method <string> -Path <string>
 [-Query <hashtable>] [-Body <Object>] [-OutFile <string>] [-WhatIf] [-Confirm]
```

## DESCRIPTION

This function sends a request through a saved or explicit connection.
It returns the response or saves the response when the caller sets OutFile.

Named connections can reuse authorization.
Explicit connections do not retain authorization.
Expired authorization causes one renewal attempt.

Requests that change data and requests that write files support ShouldProcess.
This function does not add resource-specific type names.

## EXAMPLES

### EXAMPLE 1

```powershell
Invoke-HomebridgeApiRequest -InstanceName 'Home' -Method GET -Path '/api/plugins'
```

Uses the saved connection named Home and returns the installed-plugin response.

### EXAMPLE 2

```powershell
Invoke-HomebridgeApiRequest -Url 'https://homebridge.example.com' -Credential $credential -Method GET -Path '/api/plugins'
```

Uses an explicit URL and credential without saving either value.

## PARAMETERS

### -Body

The request body.
The command serializes non-string values as JSON.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

The username and password used to authenticate with Homebridge.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ExplicitCredential
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InstanceName

The name of the saved Homebridge connection.
When omitted, exactly one saved connection must exist.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Named
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Method

The HTTP method used for the request.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -NoAuthentication

Uses an instance that does not require a username or password.
The function obtains the required authorization automatically.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ExplicitNoAuthentication
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OutFile

The optional response destination for a download.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Path

The relative Homebridge API path beginning with `/api`.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Query

Query-string keys and values appended to the request URL.

```yaml
Type: System.Collections.Hashtable
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Url

The absolute base URL of the Homebridge instance.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ExplicitNoAuthentication
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ExplicitCredential
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

None.

You cannot pipe objects to this function.

## OUTPUTS

System.Object

This function returns Homebridge API response objects or writes a response to OutFile.

## NOTES

## RELATED LINKS

[https://pshomebridge.xyz/command-reference/commands/Invoke-HomebridgeApiRequest/](https://pshomebridge.xyz/command-reference/commands/Invoke-HomebridgeApiRequest/)

[https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Invoke-HomebridgeApiRequest.ps1](https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Invoke-HomebridgeApiRequest.ps1)
