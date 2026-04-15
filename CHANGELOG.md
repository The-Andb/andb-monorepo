# Changelog

All notable changes to this project will be documented in this file.

## [2026-04-14] v3.3.7
### Added
- **AI Integration**: Initial integration of AI agents and support infrastructure.
- **UI Regression Testing**: Automated visual testing suite for all 13 themes.
- **Monorepo Synchronization**: Improved branch switching and workspace management scripts.

### Changed
- **Settings Modernization**: UI refinements for project settings and picker.

## [2026-03-11] Stable Release v3.3.6
- **andb-core/cli**: 4.0.0
- **andb-desktop**: 3.1.0
- **andb-www**: 1.1.0

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
