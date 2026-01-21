# DDL Parser Strategy Refactor

## Objective

Decouple `DDLParser` logic from static utility and `ExporterService` to allow database-specific parsing strategies (MySQL, Postgres, etc.).

## Changes

1.  **Interfaces**: Created `IDDLParser`.
2.  **Implementation**: Created `MySQLParser` with MySQL-specific logic:
    - Reserved Keywords (MySQL 8.0).
    - Definer cleanup (`DEFINER=...`).
    - Auto Increment cleanup.
3.  **Driver Integration**: Updated `MySQLDriver` to expose `getDDLParser()`.
4.  **Service Refactor**:
    - Updated `ExporterService` to use `driver.getDDLParser().normalize(ddl)`.
    - Removed hardcoded `convertKeywordsToUppercase` method.

## Verification

- [x] Interfaces defined correctly.
- [x] MySQLParser implements normalization logic specific to MySQL.
- [x] ExporterService no longer depends on static Parser or internal keyword lists.
- [x] Code pushed to repo.

## Next Steps

- Implement `getDDLGenerator()` for reverse engineering DDLs (Phase 1).
- Add Postgres Driver & Parser.
