# 🏗️ Andb Core Architecture & Evolution

This document serves as the master architectural reference for the `@the-andb/core` package and its ecosystem. It consolidates the major refactoring history (Splitting Monolith) and the forward-looking Storage Strategy.

---

## 📚 Table of Contents

1. [Part I: Package Architecture (The Great Split)](#part-i-package-architecture-the-great-split)
2. [Part II: Storage Strategy (SQLite + Files)](#part-ii-storage-strategy-sqlite--files)

---

# Part I: Package Architecture (The Great Split)

**Date:** October 27, 2024 (Completed)
**Context:** Separation of concerns between Logic, CLI, and UI.

## 1. Overview

### Goal

Decouple the monolith into 3 independent packages:

```
andb-core/    → Pure business logic (npm package)
andb-cli/     → CLI wrapper (npm package)
andb-ui/      → Desktop app (Electron)
```

### Why?

- ❌ **Before:** CLI code + business logic mixed
- ❌ **Before:** andb-ui used subprocess spawning (slow, high overhead)
- ❌ **Before:** Impossible to use andb-core as a library
- ✅ **After:** Clean separation of concerns
- ✅ **After:** Direct imports (0ms overhead)
- ✅ **After:** `andb-core` publishable to npm

## 2. Architecture Comparison

### Before

```
andb-core/
├── cli.js          ❌ Mixed CLI + logic
├── service/        ✅ Business logic
└── dependencies    ❌ Includes commander

andb-ui/
└── Uses spawn('npx', ['andb-core'])  ❌ Subprocess overhead
```

### After

```
@andb/core/         → Pure logic only
├── index.js        ✅ Clean exports
├── service/        ✅ Stateless services
└── dependencies    ✅ No CLI deps

@andb/cli/          → CLI wrapper
├── cli.js          ✅ Thin layer
└── Uses @andb/core ✅ Import directly

andb-ui/
└── require('@andb/core')  ✅ Direct import
```

## 3. Key Changes Implemented

### Phase 1: andb-core Cleanup

- **Removed Side Effects:** Services (`exporter.js`, `migrator.js`) no longer call `process.exit()` or `console.time()`. They return structured data or throw Errors.
- **Clean Index:** `index.js` now exports `ExporterService`, `ComparatorService`, etc., instead of a commander object.
- **Dependencies:** Removed `commander` from core.

### Phase 2: andb-cli Creation

- Created a thin wrapper that instantiates `Container` from core.
- Handles User Config (`andb.config.js`) loading.
- Maps CLI arguments to Service method calls.

### Phase 3: andb-ui Optimization

- **Direct Import:** Switched from `spawn('npx', ...)` to `import { Container } from '@andb/core'`.
- **Performance:**
  - Export 100 tables: **~2.2s → ~1.0s** (55% faster)
  - Connection test: **~500ms → ~50ms** (90% faster)
  - Startup overhead: **200ms → 0ms** (100% faster)

---

# Part II: Storage Strategy (SQLite + Files)

**Status:** In Progress / Architecture Defined
**Context:** Moving from File-Based persistence to a specialized Pluggable Storage Layer (SQLite/Hybrid).

## 1. Overview

Refactor storage layer from file-only to a pluggable strategy supporting **SQLite + Files** in parallel.

## 2. Storage Strategies

### A. FileStorage (Legacy/Default)

_Backward compatible with the original CLI tool._

- **Mechanism:** Writes directly to `.sql` and `.list` files in the `db/` folder.
- **Use Case:** CLI usage, git-centric workflows.

### B. SQLiteStorage (High Performance)

- **Mechanism:** Stores DDLs, Comparisons, and Mapping status in a local SQLite database (`andb.db`).
- **Use Case:** Electron App (UI), Large datasets, Complex querying/filtering needs.
- **Performance:** ~100x faster than File I/O for batch operations.

### C. HybridStorage (The "Pro" Mode)

- **Mechanism:** Writes to SQLite for instant UI feedback, but queues/syncs changes to Files for Git persistence.
- **Use Case:** Production workflows where both UI speed and Git versioning are required.
- **Code Example:**

```javascript
const storage = new HybridStorage(sqlite, files, autoExport = false)

// Write to SQLite (fast)
await storage.saveDDL(...)

// Manually export to files when "Saving" or "Pushing"
await storage.exportToFiles()
```

## 3. Data Schema (SQLite)

### Table: `ddl_exports`

| Column             | Description                   |
| ------------------ | ----------------------------- |
| `environment`      | DEV, STAGE, UAT, PROD         |
| `database_name`    | Source DB name                |
| `ddl_type`         | TABLES, PROCEDURES, FUNCTIONS |
| `ddl_name`         | Entity name (e.g., `users`)   |
| `ddl_content`      | Full SQL Create statement     |
| `file_path`        | Original file path reference  |
| `exported_to_file` | Sync status flag              |

### Table: `comparisons`

| Column             | Description                    |
| ------------------ | ------------------------------ |
| `src_environment`  | Source                         |
| `dest_environment` | Target                         |
| `ddl_name`         | Entity name                    |
| `status`           | `new`, `updated`, `deprecated` |
| `alter_statements` | JSON array of migrations       |

## 4. Integration Plan

### Container Configuration

The `Container` in `core` will accept a storage config to decide which strategy to instantiate:

```javascript
// core/service/container.js
createStorage() {
  if (config.storage === 'sqlite') return new SQLiteStorage(...)
  if (config.storage === 'hybrid') return new HybridStorage(...)
  return new FileStorage(...) // Default
}
```

### Data Flow (Hybrid)

1.  **Write:** Service -> `HybridStorage` -> SQLite (Immediate) -> Queue File Write.
2.  **Read:** Service -> `HybridStorage` -> Try SQLite (Fast) -> Fallback to Files.
3.  **Sync:** User clicks "Persist" -> `storage.exportToFiles()` -> Updates `db/` folder.

## 5. Benefits

- **Performance:** Instant UI transitions (filtering/sorting 1000s of tables).
- **Reliability:** ACID transactions prevent partial writes during large exports.
- **Flexibility:** Keeps the "Git-as-Source-of-Truth" philosophy while giving App-like speed.
