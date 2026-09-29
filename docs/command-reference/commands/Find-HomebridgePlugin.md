---
document type: cmdlet
Locale: en-US
Module Name: PSHomebridge
PlatyPS schema version: 2024-05-01
title: Find-HomebridgePlugin
---
<!-- markdownlint-disable -->

# Find-HomebridgePlugin

## SYNOPSIS

Finds Homebridge plugins in the package registry.

## SYNTAX

### Named (Default)

```
Find-HomebridgePlugin -Query <string> [-InstanceName <string>]
```

### ExplicitNoAuthentication

```
Find-HomebridgePlugin -Url <string> -NoAuthentication -Query <string>
```

### ExplicitCredential

```
Find-HomebridgePlugin -Url <string> -Credential <pscredential> -Query <string>
```

## DESCRIPTION

This function asks Homebridge to search the NPM registry and returns complete matching plugin objects.

The request contacts an external package provider.
Provider availability and rate limits can affect the request.

## EXAMPLES

### EXAMPLE 1

```powershell
Find-HomebridgePlugin -InstanceName home -Query camera
```

Returns Homebridge plugins matching camera from the NPM registry.

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

### -Query

The plugin search text.

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

PSHomebridge.PluginSearchResult.

This function returns complete plugin search-result objects.

## NOTES

## RELATED LINKS

[https://pshomebridge.xyz/command-reference/commands/Find-HomebridgePlugin/](https://pshomebridge.xyz/command-reference/commands/Find-HomebridgePlugin/)

[https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Find-HomebridgePlugin.ps1](https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Find-HomebridgePlugin.ps1)
