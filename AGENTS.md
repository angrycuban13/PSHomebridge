# PSHomebridge repository instructions

## Module design

- Target PowerShell 7. Use approved verbs, singular nouns, PascalCase parameters, and four-space indentation.
- Keep one function in each source file. Match the file name to the function name.
- Name module infrastructure functions `*-PSHomebridge`. Reserve `*-Homebridge*` names for API operations and resource wrappers.
- Route endpoint wrappers through `Invoke-HomebridgeApiRequest`. Only `Invoke-HomebridgeApiRequest` can call `Invoke-RestMethod`.
- Preserve upstream properties. Add stable `PSHomebridge.*` type names without replacing response objects.
- Keep retention, notifications, scheduling, and cross-resource retries in consumers.
- Support saved named connections and explicit URL and credential parameters.
- Encrypt only saved secrets. Never save access tokens.
- Cache access tokens by connection identity. Do not use one global token.
- Add `ShouldProcess` to each mutation and filesystem write where it applies.

## Errors, logging, and tests

- Use the module error handler at public command boundaries. Do not return raw Homebridge errors when a clear module error applies.
- Redact passwords, access tokens, authorization headers, and other secrets from errors and logs.
- Mock `Invoke-HomebridgeApiRequest` in endpoint-wrapper tests.
- Mock `Invoke-RestMethod` only in transport tests.
- Keep tests independent of live instances, ignored API specifications, credentials, and local-only files.
- Run `./PSHomebridge/tools/Test-Release.ps1` as the complete module gate.
- Do not add another root build script. `PSHomebridge/tools/Test-Release.ps1` owns analysis, build, help checks, tests, and package validation.

## Help and documentation

- Treat comment-based help in `PSHomebridge/Source` as the command contract.
- Describe behavior, inputs, outputs, limits, and side effects. Do not describe internal transport or helper implementation.
- Use reserved example domains and fake credentials. Do not use local, development, or production instance details.
- Generate command pages from the built module with `ci/New-ModuleDocs.ps1`.
- Do not edit files in `docs/command-reference` by hand.
- Commit regenerated `docs/command-reference` files when source help or exported commands change.
- Keep maintained guidance outside `docs/command-reference`.
- Use `https://pshomebridge.xyz` as the canonical documentation URL.
- Use the locked `uv` environment and Zensical configuration. Do not add a separate requirements file.
- Run `uv sync --locked --only-group docs` before documentation work.
- Run `uv run --locked --only-group docs zensical build --clean --strict` before committing documentation changes.

## Releases and repository output

- Treat `PSHomebridge/Source/PSHomebridge.psd1` and `CHANGELOG.md` as release metadata.
- Update both files for changes to module source or packaging.
- Use `PSHomebridge/tools/Prepare-Release.ps1` to prepare versions after `1.0.0`.
- Use `PSHomebridge/tools/Test-ReleaseMetadata.ps1` to check a prepared release.
- Publish only through `.github/workflows/release.yml`.
- Keep release retries idempotent. Do not move or replace an existing version tag or release asset.
- Never commit `Output`, `site`, `.venv`, credentials, research files, or live response bodies.
- Never commit access tokens, passwords, API snapshots, or other secrets.
