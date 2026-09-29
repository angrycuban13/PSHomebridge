---
title: Home
description: Install PSHomebridge and configure a saved Homebridge connection.
---

<!-- markdownlint-disable MD025 -->
# PSHomebridge
<!-- markdownlint-enable MD025 -->

PSHomebridge is a PowerShell 7 client module for the Homebridge UI API.

## Requirements

- PowerShell 7.0 or later
- Homebridge with the Homebridge UI
- A Homebridge user name and password when the server requires authentication

## Install PSHomebridge

```powershell
Install-Module -Name PSHomebridge -Repository PSGallery
Import-Module -Name PSHomebridge
```

## Save a connection

This example saves a connection that uses Homebridge authentication.

```powershell
$credential = Get-Credential
Set-PSHomebridgeConnection -InstanceName 'Home' -Url 'https://homebridge.example.com' -Credential $credential
```

<!-- markdownlint-disable MD046 -->
!!! NOTE
    By default, Windows encrypts the password for the current user and host with DPAPI.

    For portable encryption, set `PSHOMEBRIDGE_AES_KEY` to a Base64-encoded 32-byte key.
<!-- markdownlint-enable MD046 -->

If the server does not require authentication, save a connection without credentials.

```powershell
Set-PSHomebridgeConnection -InstanceName 'Home' -Url 'https://homebridge.example.com' -NoAuthentication
```

## Test the connection

```powershell
Get-HomebridgeStatus -InstanceName 'Home' -Type HomebridgeVersion
```

See the [command reference](command-reference/index.md) for all supported commands.
