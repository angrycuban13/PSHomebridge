---
document type: cmdlet
Locale: en-US
Module Name: PSHomebridge
PlatyPS schema version: 2024-05-01
title: Get-HomebridgeServerDiagnostic
---
<!-- markdownlint-disable -->

# Get-HomebridgeServerDiagnostic

## SYNOPSIS

Gets Homebridge server diagnostic information.

## SYNTAX

### Named (Default)

```
Get-HomebridgeServerDiagnostic -Type <string> [-InstanceName <string>]
```

### ExplicitNoAuthentication

```
Get-HomebridgeServerDiagnostic -Url <string> -NoAuthentication -Type <string>
```

### ExplicitCredential

```
Get-HomebridgeServerDiagnostic -Url <string> -Credential <pscredential> -Type <string>
```

## DESCRIPTION

This function returns the complete server diagnostic resource selected by Type and does not change the instance.

Pairing data can contain sensitive setup information.
The function does not write successful responses to the operational log.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-HomebridgeServerDiagnostic -InstanceName home -Type NetworkOverview
```

Returns port assignments, Matter diagnostics, and detected network conflicts.

### EXAMPLE 2

```powershell
Get-HomebridgeServerDiagnostic -InstanceName home -Type Pairing
```

Returns the Homebridge and HomeKit pairing status.

## PARAMETERS

### -Credential

Explicit credentials.

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

The saved connection name.

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

### -NoAuthentication

Indicates that the server does not require authentication.

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

### -Type

Selects the server diagnostic resource that the command returns.

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

### -Url

An explicit Homebridge URL.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

None.

You cannot pipe objects to this function.

## OUTPUTS

PSHomebridge.ServerDiagnostic.*.

This function returns complete server diagnostic objects.

## NOTES

## RELATED LINKS

[https://pshomebridge.xyz/command-reference/commands/Get-HomebridgeServerDiagnostic/](https://pshomebridge.xyz/command-reference/commands/Get-HomebridgeServerDiagnostic/)

[https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Get-HomebridgeServerDiagnostic.ps1](https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Get-HomebridgeServerDiagnostic.ps1)
