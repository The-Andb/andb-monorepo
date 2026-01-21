# PostgreSQL Support Roadmap: Zero to Hero

This document outlines the comprehensive strategy to elevate `@the-andb/core` from a MySQL-only tool to a multi-database powerhouse, starting with fully-featured PostgreSQL support.

> **Context**: "Zero to Hero" means starting from basic connectivity/abstraction (Zero) and reaching full feature parity including complex objects, sequences, and advanced migration strategies (Hero).

## 🏆 Goals

1.  **Full Feature Parity**: Support Tables, Views, Functions, Procedures, Triggers, and Events (where applicable).
2.  **Advanced Support**: Add PostgreSQL-specific features like `SEQUENCES`, `SCHEMAS`, and `MATERIALIZED VIEWS`.
3.  **Cross-DB Ready Architecture**: Ensure the core logic is abstract enough to support potential future databases (SQL Server, Oracle) without rewriting services.

---

---

## 🚀 Phase 1: First Contact (Connectivity)

_Goal: Establish a connection to PostgreSQL and return basic metadata._

- [ ] **Driver Implementation**
  - Install `pg` (node-postgres).
  - Create `core/drivers/postgres/PostgresConnection.js`.
  - Implement `connect()`, `disconnect()`, and `query()` with error handling.
- [ ] **Schema Awareness**
  - Unlike MySQL, PG uses `Schemas` (default `public`).
  - Implement logic to handle `search_path` or explicit `schema.table` addressing.
- [ ] **Basic Introspection**
  - Implement `listTables()` using `information_schema.tables`.

---

## 📊 Phase 2: Table Mastery (The Hard Part)

_Goal: Accurately fetch, parse, and compare Table structures._

- [ ] **DDL Reconstruction (The `pg_dump` substitute)**
  - PG doesn't have `SHOW CREATE TABLE`. We must rebuild DDL from catalogs.
  - Query `pg_attribute` for columns, types, defaults, and nullability.
  - Query `pg_constraint` for PKs, FKs, and Checks.
  - Query `pg_index` for indexes.
- [ ] **Type Mapping Matrix**
  - Handle `SERIAL` vs `INTEGER GENERATED ALWAYS AS IDENTITY`.
  - Handle `VARCHAR` vs `TEXT` vs `CHARACTER VARYING`.
  - Handle Arrays (e.g., `text[]`) and JSONB.
- [ ] **Comparison Logic**
  - Implement `PostgresDDLHandler.normalize()` to handle quoting (`"ColName"` case sensitivity).

---

## 📜 Phase 3: Code Objects (Logic)

_Goal: Support Views, Functions, and Procedures._

- [ ] **Views & Materialized Views**
  - Query `pg_views` for standard views.
  - Query `pg_matviews` for materialized views (New DDL Type: `MATERIALIZED_VIEWS`).
  - **Dependency Sorting**: PG is strict. Ensure Views creation order respects dependencies.
- [ ] **Functions & Procedures**
  - Handle `plpgsql`, `sql`, and `c` languages.
  - Parse `pg_proc` to reconstruct `CREATE OR REPLACE FUNCTION ...`.
  - **Signature Handling**: PG allows function overloading (same name, different args). The ID must be `Name + Signature`, not just `Name`.

---

## ⚡ Phase 4: Advanced Features (Triggers & Seq)

_Goal: Complete the feature set with PG specifics._

- [ ] **Sequences**
  - New DDL Type: `SEQUENCES`.
  - Compare `start`, `increment`, `min/max`, and `cycle` properties.
- [ ] **Triggers**
  - Query `information_schema.triggers`.
  - Handle `FOR EACH ROW` vs `FOR EACH STATEMENT`.
  - Handle `BEFORE`, `AFTER`, `INSTEAD OF`.

---

## ⭐️ Phase 5: Hero Status (Optimization & Polish)

_Goal: Production-ready robustness and developer experience._

- [ ] **SSH Tunneling**: Native support using `ssh2` to connect to RDS/Cloud SQL in private subnets.
- [ ] **Connection Pooling**: Optimize `pg.Pool` usage for high-concurrency operations.
- [ ] **Parallel Processing**: Introspect multiple schemas concurrently.
- [ ] **Testing**: Dockerized E2E tests comparing real PG instances.

---

## 🧠 Technical Deep Dive

### 1. System Catalog Queries (Cheatsheet)

Unlike MySQL's `SHOW CREATE`, we live in `pg_catalog`.

**Get Columns:**

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = $1 AND table_name = $2
ORDER BY ordinal_position;
```

**Get Functions:**

```sql
SELECT p.proname, pg_get_functiondef(p.oid)
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = $1;
```

### 2. The Identity Problem (Overloading)

In MySQL, `DROP FUNCTION foo` works.
In Postgres, `DROP FUNCTION foo` fails if overloaded. You need `DROP FUNCTION foo(int, text)`.
_Solution_: Our internal "Name" for functions must include the signature hash or full signature string.

### 3. Case Sensitivity

MySQL is often case-insensitive (OS dependent). Postgres is sensitive if quoted.
_Strategy_: Always Quote Identifiers (`"TableName"`) in generated DDL to maintain strict correctness, or apply a "Lowercase Policy" if desired.

---

_Updated: 2026-01-21 by Antigravity_
