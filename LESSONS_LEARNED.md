# PSStarr lessons learned and agent handoff

## Purpose

Use this file before changing PSStarr. It consolidates the prior agent handoffs about architecture, API design, security, testing, documentation, releases, dependency management, and workspace safety.

`AGENTS.md` remains authoritative. Historical commit IDs, test counts, versions, branches, pull requests, workflow runs, and local paths in old handoffs were evidence from earlier sessions, not permanent requirements.

## Verified repository state

This audit was completed on 2026-09-27 at commit `3129c33` on `main`, which matched `origin/main` and tag `v1.0.1` locally.

The current repository does not contain the defects recorded in the prior handoffs:

- The release job installs `Configuration 1.6.0` before `Test-ModuleManifest` resolves the manifest dependency.
- The release job verifies the validated archive digest before expansion.
- The archive expands into `release-package/PSStarr`, preserving the directory name required by `Publish-Module`.
- PowerShell Gallery publication is idempotent, and the GitHub release path verifies the tag, assets, and digest on retries.
- Release metadata comes from the manifest; release package paths are not hardcoded to `1.0.0`.
- Pull requests validate, while ordinary `main` pushes publish only when the manifest changes; manual dispatch requires the exact stable manifest version from `main`.
- The module and repository tools use `Set-StrictMode -Version 3.0`, not `Latest`.
- `Invoke-StarrApiRequest` remains the only production `Invoke-RestMethod` boundary.
- Saved configuration masks API keys, rejects redacted keys as updates, and supports DPAPI or external-key AES-256 without an implicit plaintext fallback.
- State-changing public commands use `SupportsShouldProcess`.
- Radarr and Sonarr use API v3; Prowlarr-specific wrappers use API v1.
- The generated command reference contains 127 Markdown files for 126 exported commands plus its index.
- Documentation navigation is controlled by `docs/.nav.yml`; there is no nested command-reference navigation file.
- Documentation uses the locked `uv` environment and preserves the configured logo and favicon.
- Test files use durable domain names; no `Remaining`, `Supplemental`, or `UxCommands` test files remain.

The full release gate passed during this audit:

- 561 tests passed.
- 0 tests failed.
- 2 opt-in integration tests were skipped.
- 126 exported commands were validated.
- Module version 1.0.1 was built and packaged.

The first sandboxed gate attempt failed before test execution because Pester 5.7.1 could not create `HKCU:\Software\Pester`. Running the same gate with the required registry access passed. This is an execution-environment restriction, not a repository defect.

## Product boundary

PSStarr is a reusable PowerShell 7 API client for Radarr, Sonarr, and Prowlarr. It is not a scheduler or workflow engine.

Keep scheduling, notification policy, desired-state loops, cross-resource retries, multi-step media workflows, and application lifecycle management in consuming projects.

Add public commands only for broadly useful API primitives or verified consumer requirements. Do not add endpoints to claim complete API coverage. Review consumer HTTP routes and the dated local API research before adding a write operation; do not guess upstream behavior from memory.

Keep the advanced escape hatches:

- `Invoke-StarrApiRequest` supports unsupported endpoints.
- `Invoke-StarrCommand` is the canonical advanced command interface.
- `Start-StarrCommand` exists only for compatibility.
- Typed facades cover common refresh, rescan, rename, and tightly scoped search operations.

## Public API and output contracts

Use `InstanceName` for saved-connection selection in application-facing commands. Only `*-PSStarrInstance` configuration commands use `Name` for the configuration record.

`Set-PSStarrInstance` must permit partial updates of an existing record. Creating a record still requires `Application`, `Url`, and `ApiKey`.

Shared commands with explicit credentials must expose an application discriminator and reject unsupported applications before transport.

Use typed parameters and validate route-specific combinations early:

- Positive resource IDs and ID arrays.
- Page and page-size values starting at 1.
- Typed booleans instead of string switches.
- Descriptive names such as `*IdFilter` for ambiguous filters.
- ISO 8601 dates with reversed ranges rejected before transport.
- Repeated ordinary array query keys; CSV only when the upstream controller requires it.

Preserve upstream response data. Add stable `PSStarr.*` type names and default format views without replacing responses with lossy presentation objects. `Format-List *` and `Select-Object *` must still expose all upstream properties.

Stream ordinary collections, preserve paging envelopes, and return one resource for ID routes. Do not fabricate empty arrays or placeholder objects. Add property-name pipeline binding only for natural parent-to-child reads; searches and server-filesystem inspection require explicit input.

Prowlarr indexer status records are not the configured indexer inventory. Use the indexer resource command for inventory.

## Mutation safety

Every state change must support `ShouldProcess`, `-WhatIf`, and appropriate confirmation behavior.

`Remove-StarrTag` deletes the tag resource. It does not detach a tag from media.

Media-tag commands use `Action` with `Add` and `Remove`. Friendly tag names must resolve through the tag endpoint before mutation. A missing name must warn and cause no mutation; ambiguous names must also be handled before the update request.

Provider searches can consume quotas, collection-monitoring changes can trigger upstream automation, and manual-import reads inspect server files. In live tests, search at most one or two items unless the user changes the limit. For a series, monitor one season and search one or two episodes.

Confirm recycle-bin configuration and recovery before destructive Radarr or Sonarr tests. Restore or verify deleted test media after each scenario; do not batch destructive cases without recovery checks.

## Security and error handling

Encrypt saved API keys only.

- Windows defaults to current-user/current-host DPAPI.
- Portable AES-256 requires a Base64-encoded 32-byte key in `PSSTARR_AES_KEY`.
- Plaintext on Windows must be explicitly selected.
- Encryption failure must never fall back to plaintext.

Mask recognizable credentials in provider, host, error, verbose, and log data. Never print or commit real API keys. Use obvious fake values such as `example-api-key` in examples and fixtures. Never submit a redacted configuration object as an update.

Route public-command operational failures through structured error records and the shared error handler. Keep parameter errors in validation attributes or parameter sets. Log operational failures, not successful requests; expected input errors can remain unlogged.

Dense error-helper calls are easier to audit when splatted into readable hashtables. Keep meaningful per-call differences visible: category, error ID, target, action, logging, redaction, and `NoLog`. Do not hide those policies behind a broad abstraction.

## Readability and implementation style

Follow the formatting and help rules in `AGENTS.md`. In particular:

- Put parameter attributes, types, and variables on separate lines.
- Leave blank lines between distinct actions.
- Use named booleans for compound routing conditions; collection variables must not look boolean.
- Separate discovery or filtering pipelines from later mutation.
- Apply a readability pattern consistently within each touched function.
- Do not treat short comment-based-help examples as production readability defects.
- Keep one function per ModuleBuilder source file, with public filenames matching exported function names.
- Use `git mv` for public command renames.

Module-scope strict mode should remain fixed at version 3.0. Optional API properties must be inspected through `PSObject.Properties` before access. Strict mode does not replace validation, null checks, error handling, or tests.

## Test strategy

Use fake credentials and mocked HTTP in unit tests.

- Mock `Invoke-StarrApiRequest` in endpoint tests.
- Mock `Invoke-RestMethod` only in transport tests.
- Assert both the mocked upstream shape and the request path, method, API version, query, or body.
- Keep test files grouped by durable behavior rather than implementation batch.
- Keep live tests opt-in; never print credentials or response bodies.

Live coverage must include empty results, paging envelopes, list-versus-ID behavior, saved and explicit connections, and application mismatch errors. The safe baseline covers status, health, tags, quality profiles, root folders, and disk space for each supported application.

Use this verification order:

1. Run `git diff --check`.
2. Parse changed PowerShell files with the PowerShell parser.
3. Run PSScriptAnalyzer on changed source and tool files.
4. Run focused Pester tests.
5. Run the complete Pester suite after broad public-contract changes.
6. Run `PSStarr/tools/Test-Release.ps1` before release-readiness claims, merges into release work, or publication.
7. Inspect remote workflow jobs and failed logs rather than inferring failure from a skipped later step.
8. Verify the Gallery package, GitHub tag, release, assets, and digest after publication.

On this Windows host, prepend `C:\Users\noot\OneDrive\Documents\PowerShell\Modules` to `PSModulePath` and import Pester 5.7.1 explicitly when module discovery is incomplete. Verify visible Pester, PSScriptAnalyzer, and ModuleBuilder versions before diagnosing a gate failure as a code defect.

Pester can require write access to `HKCU:\Software\Pester`. If the sandbox denies it, rerun with that access before interpreting the result.

## Release workflow gotchas

Treat every GitHub Actions job as a clean machine. `needs:` transfers order and declared outputs; artifacts transfer files. Neither transfers installed PowerShell modules, executables, or process state.

Install every dependency in each job before its first consumer. `Test-ModuleManifest`, `Import-Module`, and build tools can resolve `RequiredModules` earlier than expected.

Publish the exact artifact produced by validation. Do not rebuild separately for PowerShell Gallery and GitHub. Keep publication after validation, digest verification, and archive expansion.

Pull-request success does not prove a conditional push-only or dispatch-only release path. Review and exercise pre-publication behavior separately where practical.

A skipped GitHub release step does not prove the release job never ran; an earlier publication step may have failed. Inspect the job and failed logs:

```powershell
gh run view <run-id> --json status,conclusion,event,jobs,url
gh run view <run-id> --log-failed
```

Compare the workflow at the failing commit with local changes so uncommitted edits are not mistaken for the workflow GitHub ran.

Do not rerun an old failed workflow when the fix exists only in a newer workflow definition. Dispatch the corrected workflow from `main` with the exact manifest version.

## Documentation and dependency management

The root `docs/.nav.yml` controls site navigation. Do not create `docs/command-reference/.nav.yml`.

Generated command pages are derived from the built module. Do not edit them directly; change comment-based help, build the module, and run `ci/New-ModuleDocs.ps1`.

Preserve the generator's corrections for authoritative INPUTS and OUTPUTS, type-name cleanup, duplicate `System.Object` removal, example code blocks and descriptions, empty metadata removal, command links, and fake API keys.

The documentation environment uses the locked `uv` configuration. Do not add a parallel requirements workflow. Build with:

```console
uv sync --locked --only-group docs
uv run --locked --only-group docs zensical build --clean --strict
```

A local Zensical process can hold the cache or output lock. Check for a running server before changing configuration. Windows sandbox failures involving the WinGet `uv.exe` shim or a Zensical native DLL are environment restrictions when the same locked build succeeds outside the sandbox.

The generator writes UTF-8 with LF endings. Distinguish real content changes from CRLF normalization noise with `git diff --ignore-space-at-eol`. Do not commit all generated pages solely because line endings changed.

Keep the root README concise and direct detailed usage, development, and release procedures to the website.

Renovate should keep its current risk boundary: delayed updates, early-Monday Central scheduling, dashboard visibility, automerge only for low-risk patch/digest/pin changes, and manual review for minor, major, and Python-runtime updates. The hosted Renovate app must be enabled before the configuration can create pull requests.

## Workspace and Git safety

Run `git status --short --branch` before edits and before every commit, branch switch, merge, or push. The user or another agent can change the worktree between turns.

Preserve unrelated changes and stage explicit paths. Do not use broad staging in a mixed worktree.

Before creating a branch, identify the requested fixed point instead of assuming the current `HEAD` is correct. Commit source-branch work before switching or merging. When conflicts contain complementary changes, preserve both sides rather than selecting one whole side.

Before pushing to a pull-request branch, confirm that the pull request is still open. A commit pushed after a pull request was merged is not added to that merged pull request; create a new branch and pull request.

Generated output such as `site/` can appear after tooling runs. Confirm which command created it, resolve the exact path inside the workspace, and remove only that generated directory. Never delete unrelated untracked files.

Local live-test media under `D:\PSStarr Media Library` requires a session started with that directory as an additional writable root. Writable roots cannot be added to an active session. Restart with `--add-dir`; do not disable the sandbox globally.

If the standalone Codex sandbox fails to start, inspect the newest `.codex\.sandbox\sandbox.*.log`. A missing `codex-command-runner.exe` beside the executable or under `codex-resources` is a package-layout failure, not a PowerShell, Defender, AppX, or API-key failure.

## Agent handoff checklist

1. Read `AGENTS.md` and this file.
2. Inspect the branch, commit, dirty state, manifest version, and relevant API research.
3. Separate current facts from historical evidence.
4. Keep the task inside the API-client product boundary.
5. Preserve the transport, output, mutation, encryption, and redaction contracts above.
6. Use the smallest relevant check during development.
7. Run the complete release gate before claiming release readiness.
8. Recheck status before any Git operation and stage only explicit task files.
9. Report sandbox or dependency failures as environment failures only after reproducing the distinction.
10. Record new durable lessons here; do not create another root-level handoff unless the user requests one.
