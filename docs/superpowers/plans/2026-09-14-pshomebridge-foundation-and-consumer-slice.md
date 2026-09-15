# PSHomebridge Foundation and Consumer Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the reusable PSHomebridge transport, secure named connections, authentication, structured errors, and the plugin, version-status, scheduled-backup, and backup-download commands required by `Get-HomebridgeStatus.ps1`.

**Architecture:** ModuleBuilder composes one-function source scripts into the module. Every endpoint wrapper calls the single public `Invoke-HomebridgeApiRequest` boundary, which resolves connections, authenticates, performs HTTP, sanitizes failures, and preserves upstream response objects. Named connections persist ordinary configuration separately from encrypted credentials; downloaded files use `ShouldProcess`, explicit paths, and atomic placement.

**Tech Stack:** PowerShell 7.0+, ModuleBuilder, Pester 5.7.1+, PSScriptAnalyzer, DPAPI on Windows, AES-256 with an external 32-byte key for portable encryption.

**Spec:** `docs/superpowers/specs/2026-09-14-pshomebridge-module-design.md`

## Global Constraints

- Target PowerShell 7.0 and the Homebridge UI API 5.29.0 snapshot at `PSHomebridge/docs/research/api/api.json`.
- Use four-space indentation and one function per ModuleBuilder source script; every filename matches its function name.
- Put every parameter declaration on its own line; put attributes, type, and variable on separate lines.
- Apply equivalent validation consistently. Named connections reject null, empty, and whitespace-only values; explicit URLs use the shared URL validator.
- Leave a blank line between distinct actions. Expand multi-action conditionals and loops. Prefer multi-line implementation hashtables.
- Every function has complete comment-based help. Every `.DESCRIPTION` begins with `This function`. Do not add `.LINK`.
- Use fully qualified pipeline types consistently in `.INPUTS`, `.OUTPUTS`, and `[OutputType()]`.
- Route operational failures from public boundaries through structured errors and the shared handler. Log failures only; do not log successful calls or response bodies.
- Preserve upstream properties and add stable `PSHomebridge.*` type names.
- Use test-first red-green-refactor cycles and commit after every task.

## Plan Boundary

This plan implements the shared foundation and the consumer-required vertical slice only. Follow-up plans will add the remaining approved read families:

1. Accessories and server diagnostics.
2. Configuration and configuration-backup reads.
3. Remaining plugin/provider reads.
4. Platform, update-all, terminal-session, user, and remaining status reads.
5. Final contract reconciliation and release hardening.

The approved specification covers 59 safe GET routes. This plan intentionally implements only the routes required by the first consumer. The follow-up plans above must cover the remaining typed reads, full semantic-changelog and release preparation, permanent architecture decisions, and transfer of the exact validated artifact to protected publishing environments. Those items are deferred as separately reviewable subsystems, not omitted from the approved scope.

---

### Task 1: Build and Test Foundation

**Files:**
- Modify: `build.psd1`
- Create: `build.ps1`
- Create: `PSHomebridge/Tests/Module.Build.Tests.ps1`
- Modify: `.gitignore`
- Modify: `PSHomebridge/Source/PSHomebridge.psd1`

**Interfaces:**
- Consumes: Existing `PSHomebridge/Source/PSHomebridge.psd1`, empty `PSHomebridge.psm1`, and `PSHomebridge.Format.ps1xml`.
- Produces: `build.ps1 -Task Build`, `build.ps1 -Task Test`, and ignored `PSHomebridge/Output/PSHomebridge/<version>/` artifacts.

- [ ] **Step 1: Write failing module-build tests**

Create `PSHomebridge/Tests/Module.Build.Tests.ps1` with tests that assert the source manifest targets PowerShell 7.0, exports explicit function names rather than `*`, registers the format file, imports the built artifact, and exposes no unapproved aliases.

```powershell
Describe 'PSHomebridge module build' {
    BeforeAll {
        $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $sourceManifestPath = Join-Path $repositoryRoot 'PSHomebridge/Source/PSHomebridge.psd1'
        $manifest = Import-PowerShellDataFile -Path $sourceManifestPath
    }

    It 'targets PowerShell 7.0 or later' {
        [version]$manifest.PowerShellVersion | Should -BeGreaterOrEqual ([version]'7.0')
    }

    It 'uses explicit exports' {
        $manifest.FunctionsToExport | Should -Not -Contain '*'
        $manifest.AliasesToExport | Should -Not -Contain '*'
    }

    It 'loads the format definition' {
        $manifest.FormatsToProcess | Should -Contain 'PSHomebridge.Format.ps1xml'
    }
}
```

- [ ] **Step 2: Run the test and record the expected failure**

Run:

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Module.Build.Tests.ps1 -Output Detailed
```

Expected: FAIL because no build entry point or built module exists.

- [ ] **Step 3: Implement the build entry point**

Add ModuleBuilder settings to `build.psd1`, create `build.ps1` with explicit `Build`, `Test`, and `Clean` task selection, and add `PSHomebridge/Output/` to `.gitignore`. Build into `PSHomebridge/Output/PSHomebridge/<manifest version>/` and never modify source during build.

```powershell
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('Build', 'Test', 'Clean')]
    [string]
    $Task = 'Build'
)

$repositoryRoot = $PSScriptRoot
$sourceManifest = Join-Path $repositoryRoot 'PSHomebridge/Source/PSHomebridge.psd1'
$version = (Import-PowerShellDataFile -Path $sourceManifest).ModuleVersion
$outputDirectory = Join-Path $repositoryRoot "PSHomebridge/Output/PSHomebridge/$version"

switch ($Task) {
    'Build' {
        Build-Module -SourcePath $sourceManifest -OutputDirectory $outputDirectory -SemVer $version
    }

    'Test' {
        Invoke-Pester -Path (Join-Path $repositoryRoot 'PSHomebridge/Tests') -Output Detailed
    }

    'Clean' {
        if (Test-Path -LiteralPath $outputDirectory) {
            Remove-Item -LiteralPath $outputDirectory -Recurse -Force
        }
    }
}
```

- [ ] **Step 4: Build and run the focused tests**

Run:

```powershell
./build.ps1 -Task Build
Invoke-Pester -Path ./PSHomebridge/Tests/Module.Build.Tests.ps1 -Output Detailed
```

Expected: build exits 0 and all focused tests pass.

- [ ] **Step 5: Commit the foundation**

```powershell
git add -- .gitignore build.psd1 build.ps1 PSHomebridge/Source/PSHomebridge.psd1 PSHomebridge/Tests/Module.Build.Tests.ps1
git commit -m "build: establish module build and test foundation"
```

---

### Task 2: Shared Validation and Structured Errors

**Files:**
- Create: `PSHomebridge/Source/Private/Test-HomebridgeUrl.ps1`
- Create: `PSHomebridge/Source/Private/Protect-HomebridgeErrorMessage.ps1`
- Create: `PSHomebridge/Source/Private/Write-HomebridgeLog.ps1`
- Create: `PSHomebridge/Source/Private/Invoke-HomebridgeErrorHandler.ps1`
- Create: `PSHomebridge/Tests/Validation.Tests.ps1`
- Create: `PSHomebridge/Tests/ErrorHandling.Tests.ps1`

**Interfaces:**
- Consumes: `[string] Url`, an exception or `ErrorRecord`, stable error ID, category, and target.
- Produces: `Test-HomebridgeUrl -Url <string> -> [bool]`; `Protect-HomebridgeErrorMessage -Message <string> -Secrets <string[]> -> [string]`; `Write-HomebridgeLog -Message <string> -Path <string>` writes credential-safe plain text; `Invoke-HomebridgeErrorHandler` emits one terminating structured `ErrorRecord`.

- [ ] **Step 1: Write failing URL and redaction tests**

Test HTTP/HTTPS acceptance, rejection of relative or non-HTTP URLs, trailing-slash acceptance, password/token redaction, and preservation of nonsecret context.

```powershell
Describe 'Test-HomebridgeUrl' {
    It 'accepts an absolute HTTP or HTTPS URL' -ForEach @(
        'http://homebridge.local:8581'
        'https://homebridge.example.test/'
    ) {
        Test-HomebridgeUrl -Url $_ | Should -BeTrue
    }

    It 'rejects unsupported or relative URLs' -ForEach @(
        'ftp://homebridge.local'
        '/api/status/homebridge'
        'homebridge.local:8581'
    ) {
        Test-HomebridgeUrl -Url $_ | Should -BeFalse
    }
}
```

- [ ] **Step 2: Run focused tests and verify failure**

Run:

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Validation.Tests.ps1,./PSHomebridge/Tests/ErrorHandling.Tests.ps1 -Output Detailed
```

Expected: FAIL because the private functions do not exist.

- [ ] **Step 3: Implement URL validation and secret redaction**

Use `[System.Uri]::TryCreate`, require an absolute URI, and allow only `http` and `https`. Replace every nonempty supplied secret with `[REDACTED]` using escaped literal matching.

```powershell
function Test-HomebridgeUrl {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Url
    )

    $uri = $null
    $created = [System.Uri]::TryCreate($Url, [System.UriKind]::Absolute, [ref]$uri)

    if (-not $created) {
        return $false
    }

    $uri.Scheme -in @('http', 'https')
}
```

- [ ] **Step 4: Implement the shared error handler**

Implement `Write-HomebridgeLog` as an internal append-only plain-text writer that accepts only an already-sanitized message and creates its parent directory when necessary. Construct a sanitized `[System.Management.Automation.ErrorRecord]` with the supplied ID, category, and target; write one failure entry through `Write-HomebridgeLog` when configured; call `$PSCmdlet.ThrowTerminatingError()` at the public boundary. Do not catch parameter-validation failures.

- [ ] **Step 5: Run focused tests and PSScriptAnalyzer**

Run:

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Validation.Tests.ps1,./PSHomebridge/Tests/ErrorHandling.Tests.ps1 -Output Detailed
Invoke-ScriptAnalyzer -Path ./PSHomebridge/Source -Recurse -Severity Warning,Error
```

Expected: all tests pass and analyzer reports no warnings or errors.

- [ ] **Step 6: Commit shared validation and errors**

```powershell
git add -- PSHomebridge/Source/Private PSHomebridge/Tests/Validation.Tests.ps1 PSHomebridge/Tests/ErrorHandling.Tests.ps1
git commit -m "feat: add shared validation and structured errors"
```

---

### Task 3: Secure Named Connections

**Files:**
- Create: `PSHomebridge/Source/Private/Get-HomebridgeConnectionStorePath.ps1`
- Create: `PSHomebridge/Source/Private/Protect-HomebridgeSecret.ps1`
- Create: `PSHomebridge/Source/Private/Unprotect-HomebridgeSecret.ps1`
- Create: `PSHomebridge/Source/Private/Read-HomebridgeConnectionStore.ps1`
- Create: `PSHomebridge/Source/Private/Write-HomebridgeConnectionStore.ps1`
- Create: `PSHomebridge/Source/Public/New-HomebridgeConnection.ps1`
- Create: `PSHomebridge/Source/Public/Set-HomebridgeConnection.ps1`
- Create: `PSHomebridge/Source/Public/Get-HomebridgeConnection.ps1`
- Create: `PSHomebridge/Source/Public/Remove-HomebridgeConnection.ps1`
- Create: `PSHomebridge/Tests/Connections.Tests.ps1`
- Modify: `PSHomebridge/Source/PSHomebridge.psd1`

**Interfaces:**
- Consumes: connection `Name`, base `Url`, optional `[pscredential] Credential`, authentication-disabled flag, encryption mode, optional 32-byte AES key, and explicit plaintext consent.
- Produces: persisted records containing name, URL, authentication mode, username, and protected secret; public `PSHomebridge.Connection` objects with masked secret information.

- [ ] **Step 1: Write failing persistence and validation tests**

Cover complete creation, whitespace-only name rejection, shared URL-validator use, duplicate-name rejection, partial update, DPAPI round trip on Windows, AES round trip with exactly 32 bytes, invalid AES key rejection, explicit plaintext requirement, encryption failure without fallback, masked output, removal `ShouldProcess`, and preservation of omitted update fields.

```powershell
It 'rejects a whitespace-only connection name' {
    { New-HomebridgeConnection -Name '   ' -Url 'https://homebridge.test' -NoAuthentication } |
        Should -Throw
}

It 'requires exactly 32 bytes for portable AES encryption' {
    { New-HomebridgeConnection -Name 'test' -Url 'https://homebridge.test' -Credential $credential -Encryption Aes -Key ([byte[]]::new(31)) } |
        Should -Throw
}
```

- [ ] **Step 2: Run the connection tests and verify failure**

Run:

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Connections.Tests.ps1 -Output Detailed
```

Expected: FAIL because the connection commands do not exist.

- [ ] **Step 3: Implement secret protection helpers**

Use `ConvertFrom-SecureString`/`ConvertTo-SecureString` for current-user Windows protection. For portable mode, pass the caller-provided 32-byte key to those cmdlets. Store an encryption discriminator with ciphertext. Permit plaintext only through an explicit `-AllowPlaintext` parameter set. Throw on every protection failure before writing the store.

- [ ] **Step 4: Implement atomic connection-store access**

Store JSON under the platform-appropriate current-user application-data directory. Write to a sibling temporary file, validate JSON deserialization, then replace the store. Never serialize a plaintext password unless the explicit plaintext parameter set was selected.

- [ ] **Step 5: Implement public connection commands**

Use `ValidateScript` with `Test-HomebridgeUrl` for explicit URLs and `ValidatePattern('.*\S.*')` for names. `New` requires a complete record. `Set` updates only bound fields. `Get` returns masked `PSHomebridge.Connection` objects. `Remove` uses `SupportsShouldProcess` with `ConfirmImpact = 'High'`.

- [ ] **Step 6: Run focused tests and analyzer**

Run:

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Connections.Tests.ps1 -Output Detailed
Invoke-ScriptAnalyzer -Path ./PSHomebridge/Source -Recurse -Severity Warning,Error
```

Expected: all tests pass and analyzer reports no warnings or errors.

- [ ] **Step 7: Export and commit connection commands**

Add the four public commands explicitly to `FunctionsToExport`, rebuild, import the built module, and verify `Get-Command -Module PSHomebridge` contains all four.

```powershell
git add -- PSHomebridge/Source/Private PSHomebridge/Source/Public PSHomebridge/Source/PSHomebridge.psd1 PSHomebridge/Tests/Connections.Tests.ps1
git commit -m "feat: add secure named Homebridge connections"
```

---

### Task 4: Authentication and Public Transport

**Files:**
- Create: `PSHomebridge/Source/Private/Resolve-HomebridgeConnection.ps1`
- Create: `PSHomebridge/Source/Private/Get-HomebridgeAccessToken.ps1`
- Create: `PSHomebridge/Source/Private/Clear-HomebridgeAccessToken.ps1`
- Create: `PSHomebridge/Source/Public/Invoke-HomebridgeApiRequest.ps1`
- Create: `PSHomebridge/Tests/Authentication.Tests.ps1`
- Create: `PSHomebridge/Tests/Transport.Tests.ps1`
- Modify: `PSHomebridge/Source/PSHomebridge.psd1`

**Interfaces:**
- Consumes: named connection or explicit `Url` plus `Credential`/`NoAuthentication`; HTTP method; relative route; typed query; optional body; optional `OutFile`.
- Produces: deserialized upstream objects, or a file at `OutFile`; session-memory bearer-token cache keyed by resolved connection identity.

- [ ] **Step 1: Write failing authentication tests**

Mock `Invoke-RestMethod` and verify `/api/auth/login` receives JSON `username` and `password`, `/api/auth/noauth` receives no credential body, bearer tokens remain memory-only, and neither credentials nor tokens appear in errors.

- [ ] **Step 2: Write failing transport tests**

Cover named and explicit connections, trailing-slash normalization, path escaping, query omission for null values, bearer header application, JSON serialization, one retry after HTTP 401/403, no retry for other failures, no successful-request logging, raw response preservation, and structured sanitized errors.

```powershell
It 'reauthenticates once after a rejected cached token' {
    Mock Get-HomebridgeAccessToken { 'replacement-token' }
    Mock Invoke-RestMethod {
        if ($script:attempt++ -eq 0) {
            throw [System.Net.Http.HttpRequestException]::new('401 Unauthorized')
        }

        [pscustomobject]@{
            status = 'up'
        }
    }

    Invoke-HomebridgeApiRequest -Url 'https://homebridge.test' -Credential $credential -Method Get -Path '/api/status/homebridge' |
        Should -HaveCount 1

    Should -Invoke Invoke-RestMethod -Times 2
    Should -Invoke Get-HomebridgeAccessToken -Times 1
}
```

- [ ] **Step 3: Run focused tests and verify failure**

Run:

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Authentication.Tests.ps1,./PSHomebridge/Tests/Transport.Tests.ps1 -Output Detailed
```

Expected: FAIL because authentication and transport functions do not exist.

- [ ] **Step 4: Implement connection resolution and authentication**

Resolve exactly one of a named connection or explicit parameters. Normalize URLs with `[System.UriBuilder]`. Convert credentials to the login payload only at invocation time, clear temporary plaintext variables in `finally`, and cache only the returned bearer token in module memory.

- [ ] **Step 5: Implement `Invoke-HomebridgeApiRequest`**

Use explicit parameter sets for JSON and file responses. Permit relative `/api/...` paths only. Construct `Invoke-RestMethod` parameters as a readable multi-line hashtable. On an authentication rejection, clear the cached token, authenticate once, and repeat once. Route the final operational failure through `Invoke-HomebridgeErrorHandler`.

- [ ] **Step 6: Run transport tests and analyzer**

Run:

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Authentication.Tests.ps1,./PSHomebridge/Tests/Transport.Tests.ps1 -Output Detailed
Invoke-ScriptAnalyzer -Path ./PSHomebridge/Source -Recurse -Severity Warning,Error
```

Expected: all tests pass; analyzer reports no warnings or errors.

- [ ] **Step 7: Export and commit transport**

Add `Invoke-HomebridgeApiRequest` explicitly to the manifest, rebuild, and verify its exported syntax.

```powershell
git add -- PSHomebridge/Source/Private PSHomebridge/Source/Public/Invoke-HomebridgeApiRequest.ps1 PSHomebridge/Source/PSHomebridge.psd1 PSHomebridge/Tests/Authentication.Tests.ps1 PSHomebridge/Tests/Transport.Tests.ps1
git commit -m "feat: add authenticated Homebridge API transport"
```

---

### Task 5: Installed Plugin Reads

**Files:**
- Create: `PSHomebridge/Source/Public/Get-HomebridgePlugin.ps1`
- Create: `PSHomebridge/Tests/Plugins.Tests.ps1`
- Modify: `PSHomebridge/Source/PSHomebridge.psd1`
- Modify: `PSHomebridge/Source/PSHomebridge.Format.ps1xml`

**Interfaces:**
- Consumes: connection parameters and optional `-Include` values accepted by `/api/plugins`; optional `-UpdateAvailable` client filter.
- Produces: streamed complete plugin objects with `PSHomebridge.Plugin` as the first PSTypeName.

- [ ] **Step 1: Write failing plugin wrapper tests**

Mock `Invoke-HomebridgeApiRequest`. Verify the exact GET route, typed query serialization, list streaming, complete-property preservation, PSTypeName, update filtering, an empty upstream list producing no synthetic object, and transport failure propagation.

```powershell
It 'preserves plugin objects while filtering updates' {
    Mock Invoke-HomebridgeApiRequest {
        @(
            [pscustomobject]@{ name = 'homebridge-a'; updateAvailable = $true; custom = 1 }
            [pscustomobject]@{ name = 'homebridge-b'; updateAvailable = $false; custom = 2 }
        )
    }

    $result = @(Get-HomebridgePlugin -Name 'test' -UpdateAvailable)

    $result | Should -HaveCount 1
    $result[0].name | Should -Be 'homebridge-a'
    $result[0].custom | Should -Be 1
    $result[0].PSTypeNames[0] | Should -Be 'PSHomebridge.Plugin'
}
```

- [ ] **Step 2: Run plugin tests and verify failure**

Run:

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Plugins.Tests.ps1 -Output Detailed
```

Expected: FAIL because `Get-HomebridgePlugin` does not exist.

- [ ] **Step 3: Implement the minimal wrapper and view**

Call `Invoke-HomebridgeApiRequest -Method Get -Path '/api/plugins'`, pass only bound query parameters, prepend `PSHomebridge.Plugin`, and filter without projecting properties. Add a concise table view that omits sensitive or verbose fields while leaving the underlying object complete.

- [ ] **Step 4: Run plugin, format, and analyzer checks**

Run:

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Plugins.Tests.ps1 -Output Detailed
Test-ModuleManifest -Path ./PSHomebridge/Source/PSHomebridge.psd1
Invoke-ScriptAnalyzer -Path ./PSHomebridge/Source -Recurse -Severity Warning,Error
```

Expected: all commands exit 0.

- [ ] **Step 5: Export and commit plugin reads**

```powershell
git add -- PSHomebridge/Source/Public/Get-HomebridgePlugin.ps1 PSHomebridge/Source/PSHomebridge.psd1 PSHomebridge/Source/PSHomebridge.Format.ps1xml PSHomebridge/Tests/Plugins.Tests.ps1
git commit -m "feat: add installed Homebridge plugin reads"
```

---

### Task 6: Homebridge Version Status

**Files:**
- Create: `PSHomebridge/Source/Public/Get-HomebridgeStatus.ps1`
- Create: `PSHomebridge/Tests/Status.Tests.ps1`
- Modify: `PSHomebridge/Source/PSHomebridge.psd1`
- Modify: `PSHomebridge/Source/PSHomebridge.Format.ps1xml`

**Interfaces:**
- Consumes: connection parameters and `-Type HomebridgeVersion`.
- Produces: the complete `/api/status/homebridge-version` response with PSTypeName `PSHomebridge.Status.HomebridgeVersion`.

- [ ] **Step 1: Write failing status tests**

Verify exact route/method, complete version/update properties, one-object output, PSTypeName, no fabricated object for null, and propagation of the transport error record.

- [ ] **Step 2: Run status tests and verify failure**

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Status.Tests.ps1 -Output Detailed
```

Expected: FAIL because `Get-HomebridgeStatus` does not exist.

- [ ] **Step 3: Implement version status and formatting**

Use a validated literal `Type` parameter so later status routes extend the same family without changing consumer syntax. Map `HomebridgeVersion` only to `/api/status/homebridge-version`. Preserve `installedVersion`, `latestVersion`, `updateAvailable`, and all unknown properties.

- [ ] **Step 4: Verify and commit**

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Status.Tests.ps1 -Output Detailed
Invoke-ScriptAnalyzer -Path ./PSHomebridge/Source -Recurse -Severity Warning,Error
git add -- PSHomebridge/Source/Public/Get-HomebridgeStatus.ps1 PSHomebridge/Source/PSHomebridge.psd1 PSHomebridge/Source/PSHomebridge.Format.ps1xml PSHomebridge/Tests/Status.Tests.ps1
git commit -m "feat: add Homebridge version status"
```

Expected: tests and analyzer pass before the commit is created.

---

### Task 7: Scheduled Backups and Safe Downloads

**Files:**
- Create: `PSHomebridge/Source/Private/Resolve-HomebridgeDownloadPath.ps1`
- Create: `PSHomebridge/Source/Public/Get-HomebridgeBackup.ps1`
- Create: `PSHomebridge/Source/Public/Receive-HomebridgeBackup.ps1`
- Create: `PSHomebridge/Tests/Backups.Tests.ps1`
- Modify: `PSHomebridge/Source/PSHomebridge.psd1`
- Modify: `PSHomebridge/Source/PSHomebridge.Format.ps1xml`

**Interfaces:**
- Consumes: connection parameters; optional `-Next`; optional validated backup ID; mandatory explicit `-OutFile`; optional `-Force`.
- Produces: streamed `PSHomebridge.Backup` metadata, a `PSHomebridge.BackupSchedule` object, or `[System.IO.FileInfo]` for a completed download.

- [ ] **Step 1: Write failing backup metadata tests**

Verify `/api/backup/scheduled-backups`, `/api/backup/scheduled-backups/next`, streaming, full-property preservation, and stable type names.

- [ ] **Step 2: Write failing download-safety tests**

Verify mandatory explicit `OutFile`, `WhatIf` makes no transport call, existing targets fail without `Force`, `Force` enables replacement, backup IDs are URI-escaped, downloads target a sibling temporary file, success moves the temporary file atomically, failures remove temporary files, and the result is `[System.IO.FileInfo]`.

```powershell
It 'does not download under WhatIf' {
    Receive-HomebridgeBackup -Name 'test' -BackupId 'backup-1' -OutFile $TestDrivePath -WhatIf

    Should -Invoke Invoke-HomebridgeApiRequest -Times 0
}

It 'refuses an existing destination without Force' {
    Set-Content -LiteralPath $TestDrivePath -Value 'existing'

    { Receive-HomebridgeBackup -Name 'test' -BackupId 'backup-1' -OutFile $TestDrivePath } |
        Should -Throw
}
```

- [ ] **Step 3: Run backup tests and verify failure**

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Backups.Tests.ps1 -Output Detailed
```

Expected: FAIL because the backup commands do not exist.

- [ ] **Step 4: Implement backup metadata reads**

Use explicit parameter sets for list and next-backup time. Do not put `ShouldProcess` on metadata reads. Preserve upstream objects and attach the matching type name.

- [ ] **Step 5: Implement atomic explicit downloads**

Use `SupportsShouldProcess` and `ConfirmImpact = 'Medium'`. Resolve `OutFile` to an absolute filesystem path, reject a directory destination, create a random sibling temporary name, invoke the transport with that temporary path, and move it to the final path only after success. Remove only that validated temporary file in `catch`/`finally`; never recursively delete.

- [ ] **Step 6: Verify and commit backup commands**

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Backups.Tests.ps1 -Output Detailed
Invoke-ScriptAnalyzer -Path ./PSHomebridge/Source -Recurse -Severity Warning,Error
git add -- PSHomebridge/Source/Private/Resolve-HomebridgeDownloadPath.ps1 PSHomebridge/Source/Public/Get-HomebridgeBackup.ps1 PSHomebridge/Source/Public/Receive-HomebridgeBackup.ps1 PSHomebridge/Source/PSHomebridge.psd1 PSHomebridge/Source/PSHomebridge.Format.ps1xml PSHomebridge/Tests/Backups.Tests.ps1
git commit -m "feat: add safe Homebridge backup downloads"
```

Expected: tests and analyzer pass before commit.

---

### Task 8: Contract, Style, Consumer, and Clean-Checkout Gate

**Files:**
- Create: `PSHomebridge/Tests/Contract.Tests.ps1`
- Create: `PSHomebridge/Source/Private/Get-HomebridgeRoute.ps1`
- Create: `PSHomebridge/Tests/Style.Tests.ps1`
- Create: `PSHomebridge/Tests/Consumer.Tests.ps1`
- Create: `PSHomebridge/Tests/Help.Tests.ps1`
- Create: `PSHomebridge/docs/Connections.md`
- Create: `PSHomebridge/docs/Consumer-Migration.md`
- Create: `PSHomebridge/docs/research/api/README.md`
- Create: `AGENTS.md`
- Create: `CHANGELOG.md`
- Create: `LICENSE`
- Modify: `README.md`
- Modify: `build.ps1`

**Interfaces:**
- Consumes: OpenAPI snapshot, source tree, built artifact, and the supplied consumer-call requirements.
- Produces: `Get-HomebridgeRoute -Name <string>` returning immutable method/path metadata; enforceable style/contract gates, migration documentation, research provenance, and a clean-checkout validation task.

- [ ] **Step 1: Write failing contract tests**

Parse `swaggerDoc` from `api.json`. Assert that every typed route implemented in this plan exists with the expected method. Assert that none of the six excluded GET routes appears in the typed-route registry. Assert that the API version is exactly `5.29.0` so a changed snapshot forces review.

- [ ] **Step 2: Write failing style and help tests**

Use the PowerShell parser to assert one function per `.ps1`, matching filename/function name, four-space indentation, separate attribute/type/variable parameter lines, and no `.LINK`. Import the built module and use `Get-Help` to verify synopsis, description beginning `This function`, every parameter, examples, inputs, and outputs for every exported command.

- [ ] **Step 3: Write failing consumer-coverage tests**

Assert the built module can express these calls without direct HTTP or embedded workflow logic:

```powershell
$outdated = Get-HomebridgePlugin -Name 'home' -UpdateAvailable
$version = Get-HomebridgeStatus -Name 'home' -Type HomebridgeVersion
$backups = Get-HomebridgeBackup -Name 'home'
$download = Receive-HomebridgeBackup -Name 'home' -BackupId $backups[0].id -OutFile $destination
```

Verify backup retention and Notifiarr functions are not exported.

- [ ] **Step 4: Run the new gates and verify failure**

```powershell
Invoke-Pester -Path ./PSHomebridge/Tests/Contract.Tests.ps1,./PSHomebridge/Tests/Style.Tests.ps1,./PSHomebridge/Tests/Consumer.Tests.ps1,./PSHomebridge/Tests/Help.Tests.ps1 -Output Detailed
```

Expected: FAIL until route metadata, help, and documentation/build gates are complete.

- [ ] **Step 5: Add route metadata and complete help**

Add a private immutable route map consumed by wrappers and contract tests. Complete all public and private help to the global style contract. Do not duplicate routes in tests; derive expected contract data from the route map and compare it with OpenAPI.

- [ ] **Step 6: Write documentation and provenance**

Document named and explicit connections, DPAPI/AES/plaintext security behavior, consumer migration, provider effects, sensitive outputs, and download semantics. Record:

```text
Contract: Homebridge UI API Reference
OpenAPI: 3.0.0
API version: 5.29.0
Snapshot reviewed: 2026-09-14
Original source URL: Unknown; user-supplied local snapshot
```

Add an MIT license and an `Unreleased` semantic changelog entry covering the foundation and consumer slice. Create repository `AGENTS.md` with the approved permanent architecture and PowerShell coding rules; do not copy temporary plan steps into it.

- [ ] **Step 7: Implement the clean-checkout verification task**

Add `./build.ps1 -Task Verify` that runs analyzer, builds from the manifest version, validates the manifest/exports/help/format data, runs all tests, and rejects unexpected package files. It must not publish, tag, commit, or rebuild for multiple destinations.

- [ ] **Step 8: Run the complete verification gate**

Run:

```powershell
./build.ps1 -Task Verify
git diff --check
git status --short
```

Expected: verification exits 0; `git diff --check` exits 0; status contains only the intended task files plus any pre-existing unrelated untracked files.

- [ ] **Step 9: Commit the verified consumer slice**

```powershell
git add -- AGENTS.md README.md CHANGELOG.md LICENSE build.ps1 PSHomebridge/Source PSHomebridge/Tests PSHomebridge/docs
git commit -m "feat: complete PSHomebridge consumer API slice"
```

---

## Completion Evidence

Before claiming this plan complete, capture fresh output from:

```powershell
./build.ps1 -Task Verify
Import-Module ./PSHomebridge/Output/PSHomebridge/1.0.0/PSHomebridge.psd1 -Force
Get-Command -Module PSHomebridge | Sort-Object Name
Get-Help Get-HomebridgePlugin -Full
Get-Help Receive-HomebridgeBackup -Full
git diff --check
git status --short
```

The handoff must report exact test counts, analyzer results, exported commands, built artifact path, and any live tests not run. Do not publish or modify the external consumer script in this plan.
