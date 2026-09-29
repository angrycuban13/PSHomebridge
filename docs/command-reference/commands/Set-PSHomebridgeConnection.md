---
document type: cmdlet
Locale: en-US
Module Name: PSHomebridge
PlatyPS schema version: 2024-05-01
title: Set-PSHomebridgeConnection
---
<!-- markdownlint-disable -->

# Set-PSHomebridgeConnection

## SYNOPSIS

Creates or updates a saved PSHomebridge connection.

## SYNTAX

### All

```
Set-PSHomebridgeConnection [-InstanceName] <string> [[-Url] <string>] [[-Credential] <pscredential>]
 [-NoAuthentication] [-EncryptionMode <string>] [-WhatIf] [-Confirm]
```

## DESCRIPTION

This function creates or updates one saved connection.
A new connection requires Url and either Credential or NoAuthentication.

An existing connection keeps values that the caller omits.
Credential passwords use the selected storage mode.
The function never saves access tokens.

The operation supports ShouldProcess.
The result contains `********` instead of the password.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-PSHomebridgeConnection -InstanceName 'Home' -Url 'https://homebridge.example.com' -Credential $credential
```

Creates or replaces the authenticated connection named Home.

### EXAMPLE 2

```powershell
Set-PSHomebridgeConnection -InstanceName 'Home' -Url 'https://homebridge.example.com' -NoAuthentication
```

Creates or replaces the connection named Home for an instance with authentication disabled.

### EXAMPLE 3

```powershell
Set-PSHomebridgeConnection -InstanceName 'Home' -Url 'http://localhost:8582'
```

Updates only the URL of an existing connection.

## PARAMETERS

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
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EncryptionMode

The password storage mode.
The default is Dpapi on Windows and None on other platforms.
Aes256 requires PSHOMEBRIDGE_AES_KEY to contain exactly 32 Base64-encoded bytes.

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

### -InstanceName

The name of the saved Homebridge connection.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -NoAuthentication

Configures an instance with Homebridge authentication disabled.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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
- Name: (All)
  Position: 1
  IsRequired: false
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

PSHomebridge.Connection

This function returns a redacted saved-connection configuration object.

## NOTES

## RELATED LINKS

[https://pshomebridge.xyz/command-reference/commands/Set-PSHomebridgeConnection/](https://pshomebridge.xyz/command-reference/commands/Set-PSHomebridgeConnection/)

[https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Set-PSHomebridgeConnection.ps1](https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Set-PSHomebridgeConnection.ps1)
