---
document type: cmdlet
Locale: en-US
Module Name: PSHomebridge
PlatyPS schema version: 2024-05-01
title: Get-PSHomebridgeConnection
---
<!-- markdownlint-disable -->

# Get-PSHomebridgeConnection

## SYNOPSIS

Gets saved PSHomebridge connections without exposing passwords.

## SYNTAX

### All

```
Get-PSHomebridgeConnection [[-InstanceName] <string>]
```

## DESCRIPTION

This function returns one or all saved connections.
Each result contains its name, URL, authentication mode, username, and password storage mode.

Credential passwords appear as `********`.
The function does not decrypt passwords or change saved configuration.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-PSHomebridgeConnection
```

Returns every saved connection with its password redacted.

### EXAMPLE 2

```powershell
Get-PSHomebridgeConnection -InstanceName 'Home'
```

Returns the saved connection named Home with its password redacted.

## PARAMETERS

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

This function returns redacted saved-connection configuration objects.

## NOTES

## RELATED LINKS

[https://pshomebridge.xyz/command-reference/commands/Get-PSHomebridgeConnection/](https://pshomebridge.xyz/command-reference/commands/Get-PSHomebridgeConnection/)

[https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Get-PSHomebridgeConnection.ps1](https://github.com/angrycuban13/PSHomebridge/blob/main/PSHomebridge/Source/Public/Get-PSHomebridgeConnection.ps1)
