# 🧪 Core Engine Testing Plan

> Updated: Feb 24, 2026

## Current Test Coverage

### E2E Scenario Matrix (32 tests)

- 3 no-change normalization tests (zero false positive verification)
- 12 ALTER TABLE operation tests (column, index, FK)
- 2 production-realistic schema evolution tests
- 3 combined migration stress tests
- - legacy scenarios (add/modify/drop/view/proc/trigger)

### Sandbox Execution Layer (21 tests)

- Real MySQL 8.0 execution via Docker
- Ephemeral databases per scenario (CREATE → ALTER → VERIFY → DROP)
- Structural comparison: columns, indexes, FKs
- 5 bugs found and documented

### Unit Tests (Core)

- `comparator.test.js`: Schema diff logic
- `migrator.test.js`: ALTER SQL generation
- `exporter.test.js`: Introspection accuracy
- `ddl.parser.test.js`: DDL parsing edge cases

## Sprint Testing Priorities

1. **Fix 3 engine bugs** → Un-skip from sandbox → 24 sandbox tests
2. **Add exit code tests** → `andb compare` returns 0/1/2
3. **Add JSON output tests** → `--format json` produces valid JSON
4. **Performance benchmark** → 300 tables, 1000 indexes, 200 FKs

## Future

- MySQL 5.7 compatibility matrix
- MariaDB best-effort testing
- Large schema benchmarks (2000+ tables)
