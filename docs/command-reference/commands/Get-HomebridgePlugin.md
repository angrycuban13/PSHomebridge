---
document type: cmdlet
Locale: en-US
Module Name: PSHomebridge
PlatyPS schema version: 2024-05-01
title: Get-HomebridgePlugin
---
<!-- markdownlint-disable -->

# Get-HomebridgePlugin

## SYNOPSIS

Gets installed Homebridge plugins.

## SYNTAX

### Named (Default)

```
Get-HomebridgePlugin [-InstanceName <string>] [-Include <string[]>] [-UpdateAvailable]
```

### ExplicitNoAuthentication

```
Get-HomebridgePlugin -Url <string> -NoAuthentication [-Include <string[]>] [-UpdateAvailable]
```

### ExplicitCredential

```
Get-HomebridgePlugin -Url <string> -Credential <pscredential> [-Include <string[]>]
 [-UpdateAvailable]
```

## DESCRIPTION

This function returns installed plugins and preserves all properties returned by Homebridge.

Include accepts only config.

UpdateAvailable returns only plugins that report an available update.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-HomebridgePlugin -InstanceName home -UpdateAvailable
```

Returns complete installed-plugin objects that report an available update.

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

### -Include

Optional API extras such as config.

```yaml
Type: System.String[]
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

### -UpdateAvailable

Returns only plugins reporting an available update.

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

PSHomebridge.Plugin.

This function returns complete plugin objects.

## NOTES

## RELATED LINKS

[https://pshomebridge.xyz/command-reference/commands/Get-HomebridgePlugin/](https://pshomebridge.xyz/command-reference/commands/Get-HomebridgePlugin/)

[https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Get-HomebridgePlugin.ps1](https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Get-HomebridgePlugin.ps1)
