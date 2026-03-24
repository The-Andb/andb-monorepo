# Changelog

All notable changes to **TheAndb UI** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.0-beta.1] - 2026-03-05

### Added

- **Telemetry & Crash Reporting**: Integrated `@sentry/electron` for robust crash reporting in both main and renderer processes.
- **Product Analytics**: Added `posthog-js` integration with automatic `$pageview` tracking and anonymous device identification.
- **Pro UI Sidebar**: Upgraded sidebar connection icons to Pro-style "Icon Chips" and replaced generic category folders with content-specific icons.
- **Git Token Guide**: Added an instructional "How to get a token?" guide in the Integrations Hub.

### Improved

- **UI Typography**: Synchronized and scaled down DDL font sizes across Global and Tree views for better readability.
- **Testing Infrastructure**: Restored E2E testing integrity by fixing Docker MySQL configuration for `sandbox.playground.spec.ts`.

### Fixed

- **Sidebar Bugs**: Resolved intermittent Sidebar Focus/Collapse state desynchronization.
- **ABI Mismatches**: Persistently resolved the `better-sqlite3` ABI mismatch that blocked unit tests.
- **Comparison Operations**: Fixed the "Comparison within the same environment 'undefined' is not permitted" connection error by correctly passing environment strings to `Andb.compare`.

## [2.3.0] - 2026-01-28

### Added

- **SQL Dump File Comparison**: Compare `.sql` dump files directly without live database connections. Perfect for offline analysis and reviewing schema changes from backups.
- **DDL Type Filtering**: Filter comparison results by DDL type (Tables, Views, Procedures, Functions, Triggers, Events) in both tree and list views.
- **Enhanced Schema Caching**: Improved sidebar schema loading with SQLite-backed persistence for faster startup times.
- **Composable Architecture**: Refactored core comparison logic into reusable Vue composables (`useCompareCore`, `useComparisonFilter`).

### Improved

- **Comparison Performance**: Optimized comparison engine with better memory handling for large schemas (1000+ objects).
- **Tree View Synchronization**: DDL type filters now synchronize between tree view and list view modes.
- **Report Generation**: Reports now use embedded Highcharts and improved dark-mode aesthetics.

### Fixed

- **TypeScript Strict Mode**: Fixed all TypeScript errors for clean production builds.
- **Sidebar Loading**: Fixed issue where DDLs were not loading in schema tab after dump file operations.
- **Connection Persistence**: Improved handling of connection state across app restarts.

### Changed

- **Electron 34**: Upgraded from Electron 28 to 34 for macOS 26 (Tahoe) compatibility.
- **Core 3.0.3**: Updated to latest @the-andb/core with improved test stability.

---

## [2.2.2] - 2026-01-19

### Added

- **DDL Type Filtering**: Filter comparison tree by object type.
- **Landing Page Updates**: New version highlights and download links.

### Fixed

- **Build errors**: Resolved TypeScript compilation issues.

---

## [2.2.0] - 2026-01-12

### Added

- **Visual Diff Engine**: Side-by-side comparison with syntax highlighting and Rainbow brackets.
- **Export Preview**: Live SQL preview with line numbers.
- **Connection Pairs**: Select source ↔ target for compare/migrate operations.
- **Auto-hide Sidebar**: Collapsible navigation with keyboard shortcuts (Ctrl+B).

### Improved

- **Performance**: SQLite-backed metadata storage for faster operations.
- **Theme Support**: Polished dark and light mode aesthetics.

---

## [2.0.0] - 2025-12-26

### Added

- Initial public release
- Electron + Vue 3 + TypeScript foundation
- Integration with @the-andb/core
- Basic export, compare, and migrate workflows

[2.3.0]: https://github.com/The-Andb/andb/releases/tag/v2.3.0
[2.2.2]: https://github.com/The-Andb/andb/releases/tag/v2.2.2
[2.2.0]: https://github.com/The-Andb/andb/releases/tag/v2.2.0
[2.0.0]: https://github.com/The-Andb/andb/releases/tag/v2.0.0
