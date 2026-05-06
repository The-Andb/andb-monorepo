---
name: the-andb-core
description: "Use when developing core business logic, database drivers, AST-based schema diffing, or orchestration logic under @the-andb/core. Examples: \"Add a new MySQL driver feature\", \"Refactor the AST schema diff engine\", \"Implement pre-flight safety checks in core\""
---

# 🏗️ Developing Core Engine & DBA Logic (@the-andb/core)

This skill covers development, refactoring, and safety guidelines for `@the-andb/core`.

## 🔒 Core Philosophy & Safety Rules

> ⚠️ **SAFETY > CORRECTNESS > ARCHITECTURE > FEATURES > SPEED**

1. **Export = Online, Compare = Offline**:
   - `EXPORT` connects to live DB to dump schemas.
   - `COMPARE` works 100% offline using SQLite caching or AST files.
   - `MIGRATE` connects to the destination live DB to run DDL.
2. **DDL is Implicit Commit**: No rollback guarantee. Always perform pre-flight checks (replication lag, active queries, disk space).
3. **AST Schema Diffing**: All schema comparison MUST be AST/semantic-based, never text-based.
4. **Locking Strategy**: Always use MySQL advisory locks (`GET_LOCK`). Never use file-based locks.
5. **No DROP Data**: Never generate `DROP TABLE` or `DROP COLUMN` in auto-migrate logic. Only logic objects (`VIEW`, `PROCEDURE`, `FUNCTION`) can use `DROP IF EXISTS` + `CREATE`.

## 📁 Key Directories

```
andb-core/
├── src/
│   ├── drivers/        # MySQL, SQL Dump drivers (Strategy Pattern)
│   ├── services/       # Comparator, Migrator, Orchestrator
│   ├── utils/          # Encryption, Parser, delimiters
│   └── index.ts        # Core public interface
```

## 🛠️ Code Conventions

- **TypeScript Only**: Strict type checking.
- **FORBIDDEN**:
  - `console.log` in core — use structured result returns.
  - Spawning core as a subprocess from UI.
  - Hardcoding database drivers — use `ConnectionFactory`.
- **Error Handling**: Return Result-style `{ success: boolean, data?, error? }` instead of throwing for expected errors.

## Checklist for Core Changes

- [ ] Verify change is environment-agnostic (no UI/Electron dependencies).
- [ ] Implement AST/semantic handling for any new schema object type.
- [ ] Return `{ success, data, error }` results.
- [ ] Verify DDL operations are dry-run by default.
- [ ] Run test suite inside `andb-core` or `andb-test` to ensure zero regression.
