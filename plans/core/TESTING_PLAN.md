# 🧪 @the-andb/core Technical Testing Plan

## 🎯 Objectives

Ensure the core engine is robust, database-agnostic, and safe for production operations.

## 📊 Current Test Suite (Jest)

Located in `core/test/`:

- **Service Integration:**
  - `comparator.test.js`: Checks schema diff logic.
  - `exporter.test.js`: Validates JDBC-like introspection.
  - `migrator.test.js`: Tests SQL generation accuracy.
- **Support Logic:**
  - `ddl.parser.test.js`: High-complexity parsing logic.
  - `monitor.test.js`: Real-time operation tracking.
- **Data Access:**
  - `repositories/*`: Unit tests for local persistence.

## 🚀 Quality Control Roadmap

### Priority 1: Semantic Correction (Short-term)

- **Goal:** Move from text-based to AST-based comparison for MySQL.
- **Action:** Extend `ddl.parser.test.js` with edge cases for Stored Procedures and complex Triggers.

### Priority 2: Infrastructure Safety (Medium-term)

- **Goal:** Verify transactional dry-runs.
- **Action:** Create `core/test/service/dry-run.test.js` to simulate migrations and verify rollbacks.

### Priority 3: Multidatabase Readiness (Long-term)

- **Goal:** Ensure the same logic works for Postgres.
- **Action:** Abstract `exporter.test.js` into generic suites that can be reused for different drivers.

## 🛠️ Tooling & Standards

- **Framework:** Jest
- **CI Trigger:** Every commit to `main` branch.
- **Coverage Goal:** 80% for `src/service` and `src/utils`.
