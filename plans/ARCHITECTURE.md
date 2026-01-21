# 🏗️ Andb Core Architecture

**Source of Truth** for the `@the-andb/core` ecosystem architecture and storage mechanisms.

---

## 📦 Package Structure (Polyrepo)

The system is decoupled into three independent packages to separate logic, tooling, and presentation.

### 1. `@the-andb/core` (The Brain)

- **Role:** Pure business logic library. Stateless.
- **Format:** NPM Package.
- **Responsibility:** Database connectivity, SQL parsing, dependency graph generation, and migration strategy execution.
- **Storage:** Agnostic (accepts `Container` config).

### 2. `@the-andb/cli` (The Tool)

- **Role:** Terminal interface.
- **Format:** NPM Binary.
- **Responsibility:** Wraps `core` to provide command-line utilities for CI/CD and scriptable workflows.
- **Default Storage:** `FileStorage` (Direct `.sql` file manipulation).

### 3. `andb-ui` (The Face)

- **Role:** Desktop Application (Electron/Vue).
- **Format:** Native App.
- **Responsibility:** Visual management, interactive conflict resolution, and complex filtering.
- **Default Storage:** `SQLiteStorage` or `HybridStorage` (Performance optimized).

---

## 💾 Storage Strategy (Pluggable Layer)

The Core supports swapping storage backends via the `Container` configuration to suit different environments (CI vs. Interactive UI).

### A. FileStorage (Default/Legacy)

- **Source of Truth:** The file system (`db/` folder containing `.sql` files).
- **Mechanism:** Direct read/write to files.
- **Ideal For:** CLI, CI/CD pipelines, simple scripting.

### B. SQLiteStorage (Performance)

- **Source of Truth:** Local SQLite database (`andb.db`).
- **Mechanism:** All DDLs and comparisons are indexed in SQL tables (`ddl_exports`, `comparisons`).
- **Ideal For:** Electron App (handling thousands of tables instantly), complex querying/filtering.

### C. HybridStorage (Production/Pro)

- **Source of Truth:** **Dual**. SQLite for runtime speed; Files for Git persistence.
- **Mechanism:**
  - **Read:** Tries SQLite first (Fast) → Falls back to Files.
  - **Write:** Writes to SQLite (Immediate) → Queues/Syncs to Files.
- **Ideal For:** Interactive workflows where Git versioning is required but UI performance is paramount.

---

## 🗄️ Internal Schema (SQLite/Hybrid)

When using SQLite-backed storage, the following schema is used to index the project state.

### Table: `ddl_exports`

| Column             | Type   | Description                                 |
| ------------------ | ------ | ------------------------------------------- |
| `environment`      | `TEXT` | `DEV`, `STAGE`, `UAT`, `PROD`               |
| `database_name`    | `TEXT` | Name of the source database                 |
| `ddl_type`         | `TEXT` | `TABLES`, `PROCEDURES`, `FUNCTIONS`         |
| `ddl_name`         | `TEXT` | Name of the entity (e.g., `users`)          |
| `ddl_content`      | `TEXT` | The full `CREATE...` statement              |
| `file_path`        | `TEXT` | Relative path to the `.sql` file (for sync) |
| `exported_to_file` | `INT`  | `0` (Pending), `1` (Synced)                 |

### Table: `comparisons`

| Column       | Type   | Description                               |
| ------------ | ------ | ----------------------------------------- |
| `src_env`    | `TEXT` | Source Environment                        |
| `dest_env`   | `TEXT` | Target Environment                        |
| `ddl_name`   | `TEXT` | Entity name                               |
| `status`     | `TEXT` | `new`, `updated`, `deprecated`            |
| `alter_json` | `JSON` | Array of migration steps/alter statements |

---

## 🔌 Implementation Reference

### Service Integration

Services (Exporter, Comparator) do not know about the storage medium. They rely on the `Container` to inject the correct instance.

```javascript
// core/service/container.js
createStorage() {
  if (config.storage === 'sqlite') return new SQLiteStorage(...)
  if (config.storage === 'hybrid') return new HybridStorage(...)
  return new FileStorage(...) // Default fallback
}
```

### Hybrid Flow Logic

```mermaid
graph LR
    User[User Action] --> S{Storage Strategy}
    S -- "Read" --> Cache[SQLite (Fast)]
    Cache -- "Miss" --> FS[File System]
    S -- "Write" --> Cache
    Cache -- "Sync/Persist" --> FS
```
