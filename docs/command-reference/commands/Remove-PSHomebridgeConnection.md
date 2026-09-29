---
document type: cmdlet
Locale: en-US
Module Name: PSHomebridge
PlatyPS schema version: 2024-05-01
title: Remove-PSHomebridgeConnection
---
<!-- markdownlint-disable -->

# Remove-PSHomebridgeConnection

## SYNOPSIS

Removes a saved Homebridge connection.

## SYNTAX

### All

```
Remove-PSHomebridgeConnection [-InstanceName] <string> [-WhatIf] [-Confirm]
```

## DESCRIPTION

This function removes one saved connection and its retained authorization.
It removes empty PSHomebridge configuration directories after the last connection.

A missing connection produces a warning.
The operation supports ShouldProcess and does not return an object.

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-PSHomebridgeConnection -InstanceName 'Home' -Confirm:$false
```

Removes the saved Homebridge connection named Home without prompting.

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

None.

This function does not return objects to the pipeline.

## NOTES

## RELATED LINKS

[https://pshomebridge.xyz/command-reference/commands/Remove-PSHomebridgeConnection/](https://pshomebridge.xyz/command-reference/commands/Remove-PSHomebridgeConnection/)

[https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Remove-PSHomebridgeConnection.ps1](https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Remove-PSHomebridgeConnection.ps1)
