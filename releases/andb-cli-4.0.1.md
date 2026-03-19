# @the-andb/cli v4.0.1 Release

## ✨ CLI & Background Worker Updates
- **v4 Configuration Support**: Refined project configuration parsing to fully support the new `andb.yaml` file-based structure. Extracted native SQLite dependencies out of the critical path to ensure compatibility across broader directory configurations.
- **Environment Interpolation**: Added native support for environment variable interpolation (e.g., `${VAR}`) inside `andb.yaml` to securely inject database connection details.
- **Stable JSON-RPC Mode**: Hardened the `BackgroundWorker` execution mode for the desktop app. The CLI now gracefully ignores non-JSON logs and strictly formats JSON-RPC responses, preventing noisy standard output from breaking communication boundaries.

## 🛠 Fixes
- Fixed "connection config not found" errors when executing `npm run compare` in external directory setups.
- Updated internal package dependencies to link with `@the-andb/core` v4.0.1.
- **CLI Process Stability**: Resolved an issue where background worker operations would crash due to upstream generator failures. The IPC architecture is now far more resilient across missing argument boundaries.
