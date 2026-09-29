# Changelog

## [Unreleased]

## [1.0.0] - 2026-09-28

### Added

- Secure named Homebridge connections with DPAPI, AES-256, and explicit plaintext storage modes.
- Per-connection in-memory access-token caching with one authentication retry.
- A public command for authenticated API requests.
- Commands for installed plugins and registry-backed plugin discovery.
- Commands for status, accessories, and server diagnostics.
- Commands for scheduled-backup discovery, creation, removal, and atomic downloads.
- Typed output and default formatting for public resource commands.
- Consistent `InstanceName` selectors across connection and API commands.
- A concise unsupported-platform error for Raspberry Pi throttling status.
