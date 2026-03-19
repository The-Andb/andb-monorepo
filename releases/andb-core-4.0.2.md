# @the-andb/core v4.0.2 Release

## ✨ Core Engine Enhancements
- **New IPC Commands**: Introduced the `compare-arbitrary` JSON-RPC operation to power the new Instant Compare capabilities in the desktop app, allowing on-the-fly AST comparisons without persisting to the database.
- **Robust Schema Intelligence**: Patched edge cases in `ComparatorService` that were triggering false positive "Equal" results during mismatched syntax analysis.
- **Improved Testing Regimens**: Asynchronous transaction handling in `StorageService` has been fortified, and Node v20 compatibility issues with native dependencies (e.g. `better-sqlite3`) have been resolved across the test suite.

## 🛠 Fixes
- Corrected database mock structures in `MigratorService` unit tests to achieve a 100% pass rate.
- Aligned heuristic and AST-based safety level classifications within `ImpactAnalysisService`.
- **Background Worker Process Hardening**: Resolved a fatal `Exit Code 1` unhandled promise rejection in `MysqlDriver` caused by missing username payloads during restricted SQL script generation.
