# PSHomebridge

PSHomebridge is a reusable PowerShell 7 client for the Homebridge UI API.

## Connection

```powershell
$credential = Get-Credential
Set-PSHomebridgeConnection -InstanceName home -Url 'https://homebridge.example' -Credential $credential

Get-PSHomebridgeConnection -InstanceName home
```

Named connections store ordinary connection data and an encrypted password. Access tokens remain in memory and are cached separately for each saved connection. Explicit `-Url` and `-Credential` or `-NoAuthentication` parameters are available for ephemeral use.

## Status and diagnostics

```powershell
Get-HomebridgeStatus -InstanceName home -Type HomebridgeVersion
Get-HomebridgeStatus -InstanceName home -Type ChildBridge
Get-HomebridgeAccessory -InstanceName home
Get-HomebridgeAccessoryLayout -InstanceName home
Get-HomebridgeServerDiagnostic -InstanceName home -Type NetworkOverview
```

`Get-HomebridgeStatus` supports `ChildBridge`, `Cpu`, `Homebridge`, `HomebridgeVersion`, `Memory`, `Network`, `NodeJs`, `RaspberryPiThrottling`, `ServerInformation`, and `Uptime`. Raspberry Pi throttling is available only on Raspberry Pi hosts.

Requesting one accessory by `-UniqueId` refreshes its current characteristics. This can contact or wake the physical device.

## Plugins

```powershell
Get-HomebridgePlugin -InstanceName home -UpdateAvailable
Get-HomebridgePluginInformation -InstanceName home -PluginName homebridge-delay-switch -Type Schema
Get-HomebridgePluginInformation -InstanceName home -PluginName homebridge-delay-switch -Type AvailableVersion
Find-HomebridgePlugin -InstanceName home -Query camera
```

Registry, release, version, and search requests contact external package or source-code providers through Homebridge. A plugin can legitimately return no schema, changelog, registry record, or release information.

## Backups

```powershell
Get-HomebridgeBackup -InstanceName home
Get-HomebridgeBackup -InstanceName home -Next
New-HomebridgeBackup -InstanceName home
Save-HomebridgeBackup -InstanceName home -OutFile './homebridge-current.tar.gz'
Save-HomebridgeBackup -InstanceName home -BackupId backup-id -OutFile './homebridge-scheduled.tar.gz'
Remove-HomebridgeBackup -InstanceName home -BackupId backup-id
```

Backup creation, download, and removal support `ShouldProcess`. Downloads use a temporary file and move it to the requested destination only after the API request succeeds.

## Intentionally unsupported

PSHomebridge does not wrap restore operations, bulk update orchestration, configuration editing, accessory mutation, service or host control, platform-specific operations, UI internals, setup, terminal sessions, or user and 2FA management. Advanced callers can use `Invoke-HomebridgeApiRequest` for unsupported endpoints.
