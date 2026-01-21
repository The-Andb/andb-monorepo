# Core Improvement Roadmap: Zero to Hero (DBA Certified Edition)

This document outlines the strategic evolution of `@the-andb/core` from a functional utility to an enterprise-grade database orchestration platform.

> **Zero to Hero**: Transforming from a single-DB, string-comparing tool (Zero) to a multi-DB, AST-parsing, intelligent platform (Hero).
>
> _Reviewed by Senior DBA (30 YOE): Focus shifted from "Functionality" to **"Safety, Stability, and Semantic Correctness".**_

---

## 🏗 Phase 0: The Great Decoupling (Foundation)

_Goal: Abstract the current MySQL logic so the Core doesn't know what DB it's talking to._

- [x] **Define Interfaces (The Contract)**
  - `IDatabaseDriver`: `connect()`, `disconnect()`, `query()`, `getIntrospectionService()`, `getDDLGenerator()`.
    - **Add**: `getSessionContext()` (ensures consistent `sql_mode`, `time_zone`, and `lock_wait_timeout`).
  - `IIntrospectionService`: `listTables()`, `getDDL(type, name)`, `getChecksums()`.
  - `IDDLGenerator`: `generateCreate(obj)`, `generateAlter(diff)`.
- [x] **Refactor MySQL Driver**
  - Move all `mysql2` logic from `services/*.js` into `core/drivers/mysql/MySQLDriver.js`.
  - Ensure all existing tests pass with the new abstraction layer.
  - **Decoupled**: `ExporterService` no longer generates SQL. Uses `IntrospectionService` to `listX` and `getXDDL`.
- [x] **Standardized Driver Set (Strategy Pattern)**
  - Implement the **Strategy Pattern** to select the correct driver at runtime based on config.
  - Create a standard suite of drivers for major SQL dialects.
- [ ] **Configuration Update**
  - Update `andb.config.js` to accept `type: 'postgres' | 'mysql' | 'mssql' | 'sqlite' | 'oracle' | 'mariadb'`.

## 🏗 Phase 1: Infrastructure & Foundation

_Goal: Solidify connectivity and decouple logic from specific implementations._

- [ ] **Unified Connection Factory (The Gateway)**
  - Centralize all connection creation logic.
  - Support **Native SSH Tunneling** (via `ssh2`) to access private databases without external port forwarding tools.
  - Implement a "Driver Registry" pattern to dynamically load drivers.
- [ ] **Abstract Driver Interface (The Contract)**
  - define `IDatabaseDriver` to force consistency across MySQL, Postgres, MSSQL, etc.
  - Methods: `connect`, `disconnect`, `query`, `startTransaction`, `commit`, `rollback`.
  - Methods: `fetchDDL(type, name)`, `listObjects(type)`.
- [ ] **Resilient Execution**
  - **Retry Policies**: Automatically retry queries on transient network errors (e.g., exponential backoff for `Deadlock found` or `Gossip protocol` errors).
  - **Connection Pooling**: Implementing smart pooling for high-throughput operations.
  - **Session Hygiene**: Ensure every connection is "clean" (e.g., `SET FOREIGN_KEY_CHECKS=0` only when safe/needed, standardizing `utf8mb4` everywhere).

---

## 🛡 Phase 2: Stability & Safety (The Guardrails)

_Goal: Ensure operations are safe, predictable, and reversible._

- [ ] **Transaction Management 2.0**
  - **Transactional Dry Run (PG/MSSQL)**: Wrap migration in a generic transaction and `ROLLBACK` at the end.
  - **Virtual Dry Run (MySQL)**: Since MySQL performs **Implicit Commits** on DDL, we cannot run true transactional dry runs.
    - _Solution_: Implement a "Shadow Dry Run" (clone schema -> migrate -> diff -> drop) or "Logic Simulation" (validate SQL syntax without execution).
  - **Interactive Approval Hooks**: Allow the UI/CLI to pause execution before dangerous ops (`DROP TABLE`, `TRUNCATE`) to ask for user confirmation.
- [ ] **State Management & Locking**
  - **Advisory Locks**: Use native DB locks (`GET_LOCK` for MySQL, `pg_advisory_lock` for PG) instead of file locks. This works in Cloud/K8s/Serverless environments.
  - **Checksum Validation**: Verify the "Source" state hasn't changed since the plan was generated.
- [ ] **Pre-flight Checks (The Pilot's Checklist)**
  - **Replication Lag**: If running on a leader, warn/block if replicas are too far behind (avoids crushing replication).
  - **Active Heavy Queries**: Detect if `ALTER TABLE` is waiting on a metadata lock caused by a long-running `SELECT`.
  - **Disk Space**: Basic check to ensure we don't `ALTER` a 500GB table on a drive with 10GB free.
- [ ] **Standardized Error Handling**
  - Replace generic errors with typed errors: `ConnectionError`, `SyntaxError`, `PermissionError`, `DependencyError`.

---

## 🧠 Phase 3: Intelligence (The Brain)

_Goal: Move from String Comparison to Semantic Understanding._

- [ ] **AST Parsing (Abstract Syntax Tree)**
  - Implement/Integrate SQL parsers (e.g., `dt-sql-parser`, `pgsql-ast-parser`).
  - **Semantic Comparison**: Compare databases based on _meaning_, not text.
    - _Example_: `COLUMN a INT` and `COLUMN a INTEGER` are identical.
    - _Example_: `CONSTRAINT x CHECK (a > 0)` vs `CONSTRAINT x CHECK ((a) > 0)` are identical.
    - _Example_: Ignore column order in constraints if DB allows it.
- [ ] **Dependency Graphing**
  - Build a dependency tree of all objects (View A depends on Table B).
  - **Topological Sorting**: Automatically determine the correct creation/drop order to avoid foreign key errors.
- [ ] **Smart Drift Detection**
  - Detect "Drift" where the actual DB state diverges from the expected Git/File state.

---

## ⚡ Phase 4: Strategy Engine (The Manager)

_Goal: Support complex workflow requirements._

- [ ] **Migration Strategies**
  - **Smart Choice Engine**: Auto-decide based on table size/complexity:
    - Small Table (<100k rows): Direct `ALTER`.
    - Medium Table (<10M rows): `ALGORITHM=INPLACE` / `CONCURRENTLY`.
    - Large Table (>10M rows): Suggest/Force **Online Schema Change**.
  - **Online Schema Change (OSC)**: Integration with tools like `gh-ost` or `pt-online-schema-change` for zero-downtime migrations.
- [ ] **Blue/Green Strategy**: Create new tables side-by-side (v2), sync data, then swap names atomically.
- [ ] **Data Seeding & Masking**
  - Module to seed reference data (Dictionaries, Lookups).
  - Basic data masking/sanitization for exporting Prod data to Dev.

---

## 🌍 Phase 5: Ecosystem Expansion

_Goal: Go beyond MySQL._

- [ ] **PostgreSQL Support**: (See [POSTGRES_PLAN.md](./POSTGRES_PLAN.md))
- [ ] **SQLite Support**: For local-first development and testing.
- [ ] **Cloud Native Integration**: Direct integration with AWS RDS / Google Cloud SQL APIs for IAM Auth.

---

## Immediate Priorities (Next 2 Weeks)

1.  **Refactor**: Extract `mysql2` calls into `drivers/mysql/MySQLDriver.js` ensuring `IDatabaseDriver` compliance.
2.  **Feature**: Implement `ConnectionFactory` with **Advisory Locks** support.
3.  **Parsers**: Upgrade `DDLParser` to include basic Semantic Normalization (removing functional whitespace/quoting differences).
