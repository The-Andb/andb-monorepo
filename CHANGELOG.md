# Changelog

All notable changes to this project will be documented in this file.

## [4.0.0-beta.5] - 2026-03-11

### Added
- **Search Content**: New `andb search` command in CLI and search functionality in Desktop to find content across database objects.
- **Go to Definition**: Navigate directly from a function or procedure call to its definition in the DDL viewer via `Cmd+Click` (Mac) or `Ctrl+Click` (Windows).
- **Resizable Columns**: Added ability to resize table columns in Table Detailed View, Connection List, and DDL Visualizer.
- **Persistent Widths**: Column widths are now saved to `localStorage` and restored automatically.

### Fixed
- Stabilized unit test suite for `MirrorDiffView` and `MigrationConfirm`.
- Improved environment variable interpolation in `andb.yaml`.
- Resolved dependency version mismatch for `better-sqlite3`.

### Changed
- Normalized project configuration structure for better multi-environment support.
- Enhanced orchestration services for more reliable schema comparison and migration.
