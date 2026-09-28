# PSHomebridge repository instructions

- Target PowerShell 7 and use approved verbs, singular nouns, PascalCase parameters, and four-space indentation.
- Keep one function per source file and match its filename.
- Name module infrastructure functions `*-PSHomebridge`; reserve `*-Homebridge*` names for API operations and resource wrappers.
- Route endpoint wrappers through `Invoke-HomebridgeApiRequest`; only `Invoke-HomebridgeApiRequest` may call `Invoke-RestMethod`.
- Preserve upstream properties and attach stable `PSHomebridge.*` type names.
- Keep workflows such as retention, notifications, scheduling, and retries across resources in consumers.
- Persist ordinary connection configuration and encrypt only secrets. Never persist access tokens.
- Support named connections and explicit URL/credential parameters. Cache tokens by connection identity, not globally.
- Every mutation and filesystem write supports `ShouldProcess` where applicable.
- Mock the shared transport in wrapper tests and mock `Invoke-RestMethod` only in transport tests.
- Never commit credentials, generated output, or live response bodies.
