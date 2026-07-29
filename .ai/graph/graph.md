# The-Andb Knowledge Graph

**Scope of this pass:** Comparator + Exporter modules only (lightweight initial pass, requested 2026-07-28 to unblock the Compare/Export stabilization work). This is **not** a full-repo graph yet — see "Next expansion" below.

Source of truth: [`graph.json`](./graph.json) (typed nodes/edges) → [`graph.cypher`](./graph.cypher) (importable). This file is a human-readable view generated from the same data; if it disagrees with the code, **the code wins** — update `graph.json` and regenerate.

## Module map

```
module:orchestration (SchemaOrchestrator — the facade every entrypoint goes through)
 ├── module:comparator
 │    ├── ComparatorService        — structural diff (DDL text, indexes, FKs, alter-statement gen)
 │    └── SemanticDiffService      — AST diff (node-sql-parser) of two DDL strings
 └── module:exporter
      ├── ExporterService         — exportSchema / exportTableData → filesystem + DdlExportEntity
      └── SchemaMirrorService     — mirrorToFilesystem (full schema DDL tree dump)

AI/MCP tool wrappers (thin, delegate to SchemaOrchestrator):
  compare_schema, diff_semantic, export_schema, get_object_ddl, analyze_ddl_risk

andb-cli PlaygroundCommand bypasses the orchestrator entirely — it `new SemanticDiffService()`s
directly for ad-hoc DDL comparison in the playground.
```

## Compare call flow

```
tool:compare_schema ──► SchemaOrchestrator.compareSchema (L71)
                            ├─► ComparatorService.compareFromStorage (L79)   [structural diff]
                            └─► SemanticDiffService.compare (L105)          [AST enrichment, TABLES only]
                                     reads/writes: DdlSnapshotEntity, ComparisonEntity

tool:diff_semantic ───► SchemaOrchestrator.semanticCompare (L121)
                            ├─► SemanticDiffService.compare (L150)          [primary path]
                            └─► ComparatorService.compareArbitraryDDL /
                                ComparatorService.compareCustomSelection    [fallback paths]

andb-cli playground ──► SemanticDiffService.compare (direct, no orchestrator, no persistence)
```

## Export call flow

```
tool:export_schema ───► SchemaOrchestrator.exportSchema (L25)
                            └─► ExporterService.exportSchema (L19)
                                     writes: DdlExportEntity
                                     + optional git auto-commit (in orchestrator, after export)

SchemaMirrorService.mirrorToFilesystem — separate full-schema DDL mirror path,
not currently wired through SchemaOrchestrator.exportSchema (no edge found — verify if intentional).
```

## Known issues (business rules encoded as graph nodes)

| Issue | Location | Impact |
|---|---|---|
| ~~`issue:semantic-diff-single-table`~~ **FIXED 2026-07-28** | `semantic-diff.service.ts:26-29` | Was: `SemanticDiffService.compare` only looked at `sourceAst[0]` / `targetAst[0]`, silently truncating multi-table DDL to one table. Now loops over all CREATE-TABLE statements on both sides, diffs matches by table name, and reports added/dropped tables. Covered by `semantic-diff.service.spec.ts` (3 tests). |
| `issue:comparator-diff-placeholder` | `comparator.service.ts:1126` | `logDiff`/`_logDetailedDiff` do basic string logging instead of a real diff algorithm — comment admits this is a stand-in ("In a real terminal we'd use 'diff' or a library"). Can misrepresent line-level DDL differences shown to the user. |

| ~~`issue:ddl-rehydrate-fallback`~~ **FIXED 2026-07-28** | `base-storage.strategy.ts` — `saveDdlExport` (L704), `getDdlExports` (L732), `_readSqlFile` (L434) | Was: **root cause of "export lắm lúc không thể hiện đúng trạng thái DDL."** `saveDdlExport` writes DDL to a `.sql` file and clears `ddl_content` from the SQLite row (to avoid bloating SQLite). Every read rehydrates content from `file_path` via `_readSqlFile`. When the recorded path didn't resolve at read time (project rename, `projectBaseDir`/`activeProjectName` drift), `_readSqlFile` fell back to (a) scanning **every other project's** folder for a same-named file — could silently return a different project's DDL — and (b) guessing across 5 DB engines — could silently return the wrong engine's DDL. Total failure returned `''` with no warning, which `getDdlExports` then left as the shown content, i.e. "empty DDL" for an object that has real content. **Fix:** removed the cross-project directory scan and the blind cross-engine guess (only guesses `mysql` for pre-multi-engine legacy paths; otherwise trusts the engine already encoded in the path); added an always-on (non-`ANDB_DEBUG`-gated) warning log when lookup fails completely, so failures are now diagnosable instead of silently wrong. This is the actual mechanism connecting `ExporterService.exportSchema` (writer) and `SchemaMirrorService.mirrorToFilesystem` (reader) — they were never two independent DB reads as first suspected; they share this file-rehydration layer, which was the real bug. |

## Entities touched

- `entity:ComparisonEntity` (`comparisons` table) — written by `ComparatorService.compareFromStorage`
- `entity:DdlSnapshotEntity` (`ddl_snapshots` table) — read as compare baseline
- `entity:DdlExportEntity` (`ddl_exports` table) — written by `ExporterService.exportSchema`

## How to extend this graph (incremental mode)

1. **Do not rebuild from scratch.** Load `graph.json`, find the nodes/edges touching the file(s) you're about to change.
2. Read only those files to refresh context.
3. Do the task.
4. Patch only the changed/added nodes and edges in `graph.json` (bump `updatedAt`), then regenerate `graph.cypher` (see the Node one-liner used to build it, or hand-edit both consistently).
5. If `git diff`/`git log` show no changes touching files this graph tracks, leave the graph untouched.

## Next expansion (not done yet — full monorepo pass)

Per the original request, the full graph should eventually also cover: business domains/bounded contexts, driver layer (mysql/postgres), storage/migrations, orchestration tools beyond compare/export, `andb-desktop` IPC + Vue components, `andb-cli` commands beyond playground, `andb-mcp`, `andb-www`, tests, env/config, and ownership. Extend this file and `graph.json` incrementally as those areas get touched — don't do a big-bang rescan.
