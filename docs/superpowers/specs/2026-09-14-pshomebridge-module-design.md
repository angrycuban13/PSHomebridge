# PSHomebridge PowerShell 7 Module Design

## Purpose

PSHomebridge is a reusable PowerShell 7 client for the Homebridge UI API. It exposes consumer-required primitives and all approved safe read-only resources without absorbing consumer workflows such as retention, notifications, scheduling, or retries across resources.

The initial consumer is `Get-HomebridgeStatus.ps1` from the `powershell-universal` repository. Its Homebridge calls require authentication, installed-plugin inspection, Homebridge version status, scheduled-backup listing, and scheduled-backup download.

## Contract

The contract is the user-supplied OpenAPI snapshot at `PSHomebridge/docs/research/api/api.json`:

- OpenAPI version: 3.0.0
- API title: Homebridge UI API Reference
- API version: 5.29.0
- Reviewed: 2026-09-14
- Original source URL: unknown; do not infer one
- Authentication: bearer JWT obtained through `/api/auth/login` or `/api/auth/noauth`
- Pagination: none declared

Connections provide the Homebridge base URL. The transport normalizes trailing slashes and appends `/api/...` routes without inventing a version prefix.

## Scope

### Included behavior

The module supports 59 safe GET routes from the 65 GET routes in the snapshot. Resource-family commands cover:

- Authentication settings and token checks
- Accessory lists and layouts
- Instance backup download, scheduled-backup listing and download, and next-backup time
- Server configuration and diagnostics
- Homebridge configuration and configuration-backup reads
- Installed plugin data, schemas, aliases, changelogs, editor context, npm lookup/search/version data, and GitHub release data
- CPU, memory, network, uptime, Homebridge, child-bridge, version, server, Node.js, and Raspberry Pi status
- Docker startup-script and HB-service startup/log reads
- Update-all plan and journal reads
- Persistent-terminal-session status
- User listing

Provider-backed plugin reads are included despite npm or GitHub traffic because the user explicitly approved them. File downloads are included because they do not mutate server state and require explicit local destinations.

### Consumer-required commands

The first vertical slice includes:

- `Get-HomebridgePlugin`, including an `-UpdateAvailable` filter that preserves complete plugin objects
- `Get-HomebridgeStatus` for Homebridge version state
- `Get-HomebridgeBackup` for scheduled-backup discovery
- `Receive-HomebridgeBackup` for explicit download to `-OutFile`

### Excluded GET routes

Six GET routes are excluded from typed wrappers:

1. `/api/accessories/{uniqueId}` because it refreshes accessory characteristics.
2. `/api/plugins/custom-plugins/homebridge-deconz/dump-file` because it exchanges credentials.
3. `/api/plugins/custom-plugins/homebridge-hue/dump-file` because it exchanges credentials.
4. `/api/plugins/settings-ui/{pluginName}/index.html` because it redeems a ticket in a UI-session workflow.
5. `/api/plugins/settings-ui/{pluginName}/{path}` because it serves a ticketed UI session.
6. `/api/setup-wizard/get-setup-wizard-token` because it creates an authentication token.

The public raw transport remains available for unsupported routes, but documentation warns that excluded routes have behavior outside the safe typed surface.

### Other exclusions

The typed v1 surface excludes every server mutation and browser-session lifecycle operation, including session-cookie restoration, refresh, logout, plugin installation, update execution, configuration writes, restore, deletion, restart, shutdown, and user mutation.

The following remain consumer workflows:

- Backup retention and deletion
- Backup-directory policy
- Notifiarr or other notifications
- Connectivity probing
- Scheduling
- Cross-resource retries
- Desired-state loops
- Update installation and service orchestration

## Safety

Every local file write uses `SupportsShouldProcess`. Download commands:

- Require an explicit `-OutFile`.
- Honor `-WhatIf`.
- Refuse to overwrite an existing file unless `-Force` is supplied.
- Sanitize server-provided filenames rather than using them as unvalidated paths.
- Avoid partial final files by downloading to a temporary sibling and moving it into place only after success.

Provider-backed plugin reads document npm/GitHub traffic and possible quotas. Reads that inspect server files or probe available ports document that they cause server work.

Config, user, pairing, and log responses can contain sensitive data. They remain complete objects for explicit access, but default views omit sensitive properties. Response bodies are never logged.

## Architecture

### Public HTTP boundary

`Invoke-HomebridgeApiRequest` is the only HTTP boundary. It:

- Resolves named or explicit connections.
- Normalizes base URLs and routes.
- Acquires and applies bearer tokens.
- Serializes typed query and body values.
- Supports JSON and explicit file responses.
- Invokes `Invoke-RestMethod`.
- Sanitizes failures.
- Returns deserialized upstream responses without lossy reshaping.

Endpoint wrappers call only `Invoke-HomebridgeApiRequest`; they never call `Invoke-RestMethod` directly.

### Connections and secrets

The public connection commands are:

- `New-HomebridgeConnection`
- `Set-HomebridgeConnection`
- `Get-HomebridgeConnection`
- `Remove-HomebridgeConnection`

Creation requires a complete URL and authentication record. Updates may be partial. Explicit URL and credential parameters support ephemeral and CI use without persistence.

Windows uses current-user DPAPI for secrets by default. Portable AES-256 storage requires an external 32-byte key. Plaintext storage requires an explicit switch. Encryption failure terminates and never falls back to plaintext. Configuration output, errors, verbose messages, and logs mask recognizable passwords and tokens. Redacted values are never reused as update input.

### Authentication lifecycle

The module supports username/password login and authentication-disabled token acquisition. Tokens stay in memory and may be reused during the module session. When the server rejects a cached token, the transport authenticates once and retries the request once.

Persistent bearer-token storage, browser cookies, session restoration, token refresh, and logout are excluded.

### Wrappers and parameters

Resource-family commands use singular approved nouns and parameter sets for closely related list and detail routes. Proposed command families include:

- `Get-HomebridgeAccessory`
- `Get-HomebridgeAccessoryLayout`
- `Get-HomebridgeAuthenticationSetting`
- `Test-HomebridgeAuthentication`
- `Get-HomebridgeBackup`
- `Receive-HomebridgeBackup`
- `Get-HomebridgeConfig`
- `Get-HomebridgePlugin`
- `Find-HomebridgePlugin`
- `Get-HomebridgeServer`
- `Get-HomebridgeStatus`
- Platform-specific commands where Docker and HB-service contracts differ

Final command names must remain discoverable without producing one public command per route. Route-specific parameters are typed, invalid combinations fail before HTTP, dates use ISO 8601, and arrays follow the upstream controller contract.

### Output and pipeline behavior

Wrappers preserve all upstream properties and prepend stable `PSHomebridge.*` PSTypeNames. Ordinary collections stream. Singular routes return one resource. Paging envelopes would be preserved, but the current contract declares no pagination. Commands never fabricate empty arrays or placeholder objects.

Natural parent-to-child operations may bind identifying properties from the pipeline. Searches, filesystem reads, downloads, and sensitive operations require explicit intent.

`PSHomebridge.Format.ps1xml` defines concise default views. `Format-List *` and `Select-Object *` continue to expose complete responses.

### Errors and logging

One private handler converts operational failures to structured `ErrorRecord` objects with stable IDs and appropriate categories. Parameter metadata and parameter sets handle input validation.

Operational failure logging is credential-safe plain text. Successful requests and response bodies are not logged by default.

### Source layout and help

The module targets PowerShell 7 and uses approved verbs, singular nouns, PascalCase parameters, and four-space indentation.

Every ModuleBuilder source script contains exactly one function. Public and private script filenames match their function names.

Every parameter declaration is on its own line. Parameter attributes, parameter types, and parameter variables are each on separate lines. Parameters with equivalent semantics receive equivalent validation. Named connections and API keys reject null, empty, and whitespace-only values. Every explicit URL uses the shared URL validator.

Distinct actions are separated by a blank line, including assignments, conditionals, loops, transport calls, and output construction. Conditionals and loops are expanded across multiple lines when their bodies assign values, perform multiple actions, or become harder to scan inline. A single-action conditional may remain compact only when readability is preserved. Implementation hashtables use readable multi-line layouts.

Every function includes comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER` for every parameter, `.EXAMPLE`, `.INPUTS`, and `.OUTPUTS`. Every `.DESCRIPTION` begins with `This function`. Functions with meaningfully different use cases or parameter sets include more than one example. `.LINK` sections are omitted unless project requirements change.

Functions that accept or return pipeline objects use fully qualified .NET type names in `.INPUTS`, `.OUTPUTS`, and `[OutputType()]`, keep those types consistent, and briefly describe them. Functions with no input or output document `None.` followed by the standard explanatory sentence.

Public commands route operational failures through structured error records and the shared error handler. Parameter validation remains in validation attributes or parameter sets. Logs remain plain-text and human-readable. Operational failures are logged, expected input errors may be emitted without logging, and successful API calls are not logged by default.

## Verification

### Unit tests

Pester transport tests mock `Invoke-RestMethod`. Endpoint tests mock `Invoke-HomebridgeApiRequest`. Tests cover:

- URL normalization and route construction
- Login and no-auth token acquisition
- Token reuse, rejection, one reauthentication, and one retry only
- Header and credential redaction
- Named connection persistence
- Complete creation and partial update behavior
- DPAPI, AES key validation, explicit plaintext, and encryption failure
- Typed path/query serialization
- Shared URL validation and consistent validation for equivalent parameter semantics
- List, singular, and file response shapes
- Stable type names and format views
- Pipeline binding boundaries
- `ShouldProcess`, `WhatIf`, overwrite refusal, and `Force`
- Temporary download cleanup and atomic final placement
- Provider-backed and sensitive-read safeguards
- PSScriptAnalyzer and repository checks for parameter layout, indentation, action spacing, one-function-per-file naming, and complete help sections

Contract tests compare every supported method/path pair with the 5.29.0 snapshot and assert that the six unsafe GET routes have no typed wrappers. There is no supported-application matrix because the module targets only Homebridge UI.

### Live tests

Live tests are opt-in and environment-driven. They suppress response bodies and perform one successful read per included resource family against a safe test instance. Downloads use a temporary path. Provider-backed and sensitive reads require separate opt-in switches. Live tests perform no server mutation.

### Release gate

A clean-checkout gate:

1. Runs static analysis on source and tooling.
2. Builds from the manifest version.
3. Validates manifest metadata, explicit exports, help, and format data.
4. Runs all unit tests.
5. Runs enabled live tests.
6. Inspects the package and rejects unexpected files.

A prepare script updates the version and changelog without committing or publishing. A manual release from the primary branch verifies the requested version, transfers the exact validated artifact to a protected environment, publishes idempotently, and creates the matching tag and release. The artifact is not rebuilt between destinations.

## Documentation

The completed module includes:

- README installation and usage
- Complete comment-based help
- MIT license
- Semantic changelog
- Permanent architectural decisions in repository `AGENTS.md`
- Dated API research metadata identifying the supplied snapshot, API version 5.29.0, review date 2026-09-14, and unknown original source URL

## Implementation Order

1. Establish build, test, and clean-checkout validation foundations.
2. Implement connection persistence, secret protection, shared errors, and transport.
3. Implement authentication and the consumer-required plugin, status, backup-list, and backup-download vertical slice with tests, help, types, and formatting.
4. Validate the consumer can replace its direct Homebridge HTTP calls while retaining its own workflows.
5. Add remaining safe resource families vertically.
6. Reconcile supported routes against the contract and exclusions.
7. Complete documentation, changelog, package inspection, and exact-artifact release automation.

Scope is re-evaluated after consumer coverage. Endpoints are not added merely to claim complete API coverage.
