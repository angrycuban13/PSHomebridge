---
document type: cmdlet
Locale: en-US
Module Name: PSHomebridge
PlatyPS schema version: 2024-05-01
title: Get-HomebridgePluginInformation
---
<!-- markdownlint-disable -->

# Get-HomebridgePluginInformation

## SYNOPSIS

Gets metadata for a Homebridge plugin.

## SYNTAX

### Named (Default)

```
Get-HomebridgePluginInformation -PluginName <string> -Type <string> [-InstanceName <string>]
 [-ReleaseVersion <string>]
```

### ExplicitNoAuthentication

```
Get-HomebridgePluginInformation -Url <string> -NoAuthentication -PluginName <string> -Type <string>
 [-ReleaseVersion <string>]
```

### ExplicitCredential

```
Get-HomebridgePluginInformation -Url <string> -Credential <pscredential> -PluginName <string>
 -Type <string> [-ReleaseVersion <string>]
```

## DESCRIPTION

This function returns the complete metadata resource selected by Type for one plugin.

Registry, AvailableVersion, and Release contact external package or source-code providers through Homebridge.
Provider availability and rate limits can affect these requests.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-HomebridgePluginInformation -InstanceName home -PluginName homebridge-example -Type Schema
```

Returns the configuration schema supplied by homebridge-example.

### EXAMPLE 2

```powershell
Get-HomebridgePluginInformation -InstanceName home -PluginName homebridge-example -Type Release -ReleaseVersion latest
```

Returns release information for the latest version through Homebridge.

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

### -PluginName

The package name of the plugin.

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

### -ReleaseVersion

The version or distribution tag used for Release metadata.
This parameter is valid only when Type is Release.

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

### -Type

Selects the plugin metadata resource that the command returns.

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

PSHomebridge.PluginInformation.*.

This function returns the complete plugin metadata response.

## NOTES

## RELATED LINKS

[https://pshomebridge.xyz/command-reference/commands/Get-HomebridgePluginInformation/](https://pshomebridge.xyz/command-reference/commands/Get-HomebridgePluginInformation/)

[https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Get-HomebridgePluginInformation.ps1](https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Get-HomebridgePluginInformation.ps1)
