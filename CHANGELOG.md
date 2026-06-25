# Changelog

All notable changes to this project will be documented in this file.

## [2026-06-19] v4.0.4
- **andb-core/cli**: 4.0.4
- **andb-desktop**: 4.0.4
- **andb-www**: 4.0.4

### Fixed
- **Live Demo Race Condition**: Fixed a bug where creating a Live Demo or Instant Compare project would accidentally steal and permanently reassign connections from the active project due to an async state loading race condition. Included an auto-recovery mechanism on startup to seamlessly restore any connections orphaned by this bug.
- **Global Schema View**: Ensure the Global Schema View immediately selects the first available connection instead of showing "Unknown", and improved the local search behavior to correctly find and highlight DDL content.


## [2026-06-17] v4.0.3
- **andb-core/cli**: 4.0.3
- **andb-desktop**: 4.0.3

### Added
- **Backwards (Reversed) Migration**: Added support for one-way backwards migrations ("Alter Source"), allowing users to apply changes directly to the source database rather than the target connection to quickly resolve minor mistakes.
- **Interactive Database Selection**: Replaced manual text inputs with an interactive dropdown selection for database pickers in both global connections and project connection settings.

### Fixed & Changed
- **DDL Name Display**: Removed text truncation (ellipsis) on the DDL name in the comparison view header to ensure the full name is always visible.
- **Cleaned Up Results List Header**: Removed the redundant "Back to Categories" button from the database overview results header.

## [2026-06-11] v4.0.2
- **andb-core/cli**: 4.0.2
- **andb-desktop**: 4.0.2

### Fixed
- **Dialect-Specific Index Parsing**: Fixed a syntax bug where SQLite standalone index creation (`CREATE INDEX ON`) was generated for MySQL tables during parsing fallback. The parser now preserves standard MySQL inline-key definitions (`KEY` and `UNIQUE KEY`) for MySQL, ensuring valid SQL is generated during ALTER migrations.
- **Migration Commas & White Space**: Fixed trailing comma generation issues when sorting indexes under specific carriage return formats (`\r\n`).
- **Orchestrator Execution Status**: Corrected migration dry-runs and execution to return a proper status rather than falsely reporting success when individual statements fail.

## [2026-06-11] v4.0.1
- **andb-core/cli**: 4.0.1
- **andb-desktop**: 4.0.1

### Added
- **Hybrid Comparison Engine**: Added aggressive routine normalization (`normalizeRoutineDDL`) in `ParserService` to ignore whitespace, comments, backticks, and formatting for procedures, functions, triggers, and views.
- **Metadata Synchronization**: Integrated schema/DDL character set and collation extraction and tracking (saved to SQLite `ddl_exports` and matched in `compareFromStorage`).
- **Seamless AI Diagnosis**: AI Diagnose button in Database Pulse Monitor now opens and streams findings directly in the main AI Assistant Panel conversation.

### Fixed
- **MySQL Routine Syntax Errors**: Corrected `cleanDefiner` to normalize spaces using `/[ \t]{2,}/g` instead of `/\s{2,}/g`, preserving newlines so that trailing parameter comments do not comment out `BEGIN` and subsequent declarations.
- **Git-Sync Path Error**: Added options fallback for target database names to resolve `TypeError: path must be a string` in `SchemaMirrorService` when source connection details are empty.
- **Batch Migrate UI Refresh**: Solved case-sensitivity mismatch (`PROCEDURES` vs `procedures`) to ensure the results map updates correctly and removes completed items from the diff list.

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
