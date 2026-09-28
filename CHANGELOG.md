# Changelog

## Unreleased

### Added

- Secure named Homebridge connections with DPAPI, AES-256, and explicit plaintext storage modes.
- Per-connection in-memory access-token caching with one authentication retry.
- Public authenticated raw transport.
- Installed-plugin and registry-backed plugin discovery commands.
- Status, accessory, and server-diagnostic resource commands.
- Scheduled-backup discovery plus backup creation, removal, and atomic current or scheduled downloads.
- Typed output, default formatting, focused Pester coverage, and deterministic build verification.
- Consistent InstanceName selectors across connection and API commands.
- Human-readable default view labels for connections, plugins, status, accessories, diagnostics, and backups.
- A concise unsupported-platform error for Raspberry Pi throttling status.
