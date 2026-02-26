# 🛡️ Quality Control Plan

> Updated: Feb 24, 2026

## Testing Architecture

| Layer               | Tool                | Coverage                                       | Status         |
| :------------------ | :------------------ | :--------------------------------------------- | :------------- |
| **E2E (CLI)**       | Jest                | 32 scenarios (playground matrix)               | ✅ Green       |
| **Sandbox (MySQL)** | Jest + Docker MySQL | 21 scenarios (ALTER execution verified)        | ✅ Green       |
| **Integration**     | Jest                | Docker MySQL driver, SSH tunnel, introspection | ✅ Established |
| **Unit (Core)**     | Jest                | Comparator, migrator, parser, exporter         | ✅ Established |
| **UI (Desktop)**    | Vitest + Playwright | Vue 3 components + Electron E2E                | ✅ Established |

## Test Inventory

### @the-andb/test (53 tests)

**E2E Playground Matrix** (`e2e/cli.playground.spec.ts`) — 32 tests:

- Tier 1: Normalization (int-display-width, implicit-btree, reorder-columns)
- Tier 2: Column positioning (add-column-first, add-column-middle)
- Tier 3: Complex indexes (fulltext, unique-to-normal, prefix-length)
- Tier 4: FK complexity (cascade-change, fk-drop, fk-multi-column)
- Tier 5: Combined migrations (combined-column-index, drop-column-with-index, full-table-evolution)
- Tier 6: Production realistic (e-commerce-users, audit-log-table)
- Legacy: add-column, modify-column, change-index, drop-index, rename-column, etc.

**Sandbox Execution Layer** (`e2e/sandbox.playground.spec.ts`) — 21 tests:

- Executes ALTER SQL on real Docker MySQL 8.0
- Verifies final schema matches expected target (columns, indexes, FKs)
- 5 known engine bugs documented and skipped with reason

### @the-andb/core (unit/integration tests)

- `comparator.test.js`: Schema diff logic
- `migrator.test.js`: SQL generation accuracy
- `exporter.test.js`: Introspection validation
- `ddl.parser.test.js`: Complex SQL parsing

## Known Engine Bugs (from Sandbox)

| Bug                           | Impact                     | Priority    |
| :---------------------------- | :------------------------- | :---------- |
| `AFTER \`FIRST\`` syntax      | Invalid MySQL SQL          | 🔴 Must fix |
| AFTER on FULLTEXT KEY         | Invalid MySQL SQL          | 🔴 Must fix |
| FK ADD before DROP            | Duplicate constraint error | 🔴 Must fix |
| Multi-table parsing           | Only first table compared  | 🟡 Document |
| Version-comment normalization | False positive MODIFY      | 🟡 Document |

## Quality Gates

- **Merge to main:** All 53 tests must pass
- **Before ship:** 24+ sandbox tests pass (after bug fixes)
- **Coverage target:** 80% for `src/modules/` in core
