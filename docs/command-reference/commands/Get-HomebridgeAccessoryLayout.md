---
document type: cmdlet
Locale: en-US
Module Name: PSHomebridge
PlatyPS schema version: 2024-05-01
title: Get-HomebridgeAccessoryLayout
---
<!-- markdownlint-disable -->

# Get-HomebridgeAccessoryLayout

## SYNOPSIS

Gets the Homebridge accessory layout.

## SYNTAX

### Named (Default)

```
Get-HomebridgeAccessoryLayout [-InstanceName <string>]
```

### ExplicitNoAuthentication

```
Get-HomebridgeAccessoryLayout -Url <string> -NoAuthentication
```

### ExplicitCredential

```
Get-HomebridgeAccessoryLayout -Url <string> -Credential <pscredential>
```

## DESCRIPTION

This function returns the accessory and room layout for the authenticating user.
It preserves every property returned by Homebridge.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-HomebridgeAccessoryLayout -InstanceName home
```

Returns the saved accessory and room layout for the current user.

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

PSHomebridge.AccessoryLayout.

This function returns complete accessory-layout objects.

## NOTES

## RELATED LINKS

[https://pshomebridge.xyz/command-reference/commands/Get-HomebridgeAccessoryLayout/](https://pshomebridge.xyz/command-reference/commands/Get-HomebridgeAccessoryLayout/)

[https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Get-HomebridgeAccessoryLayout.ps1](https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Get-HomebridgeAccessoryLayout.ps1)
