# 🧠 The Andb - AI Memory

> Long-term memory for AI sessions. Update at end of each session.

---

## 🏗️ Architecture Overview

- **Monorepo**: `core`, `ui`, `cli`, `landing`
- **Core principle**: All logic in `@the-andb/core`
- **New Core Engine**: `@the-andb/core-nest` (Framework/TypeScript) - _In Development_
- **UI**: Electron + Vue 3, presentation only
- **Database focus**: MySQL schema comparison & sync
- **Current Phase**: Phase 3 — Expansion (Stable Release & Advanced Features)

---

## 📐 Coding Conventions

- TypeScript for UI and new core code
- Vue 3 Composition API (`<script setup>`)
- Framework for Core (Modules, Services, DI)
- Tailwind CSS v3 for styling
- All text must be i18n localized
- Credentials encrypted via `core/src/utils/crypt.ts`
- Error handling: Result-style `{ success, data?, error? }`
- No `console.log` in core

---

## ⚠️ Critical Safety Rules

- DDL = implicit commit, NO rollback guarantee
- Use `GET_LOCK` for MySQL advisory locks
- Pre-flight checks: replication lag, long queries, disk space
- Schema diffing MUST be AST/semantic-based
- DRY-RUN by default for all DDL operations
- **Twin Engine Refactor**: `core-nest` must maintain strict 1:1 parity with `core`. Verify with "Mirror Tests".

---

## ❌ Approaches Tried & Rejected

<!-- Document failed approaches here to avoid repeating them -->

| Date    | Approach             | Why Rejected                                |
| ------- | -------------------- | ------------------------------------------- |
| 2026-01 | File-based locks     | Not reliable in multi-process, use GET_LOCK |
| 2026-01 | Text-based diff      | Not semantic, use AST parsing               |
| 2026-01 | Business logic in UI | Violates layering, keep in core             |

---

## 💡 Key Learnings

<!-- Important discoveries to remember -->

- Dump files are static, cannot migrate/backup
- DBA operations need restriction for dump sources
- Parser must handle custom delimiters (triggers, procedures)
- Deep before Wide strategy — master MySQL first
- Storage: FileStorage (CLI), SQLiteStorage (UI), HybridStorage (Pro)
- **Store Init (Pinia)**: Use `initPromise` guards to prevent race conditions during concurrent `reloadData()` or component mounting. Overwriting `ref` state during slow loads is a major source of bugged "ghost items".
- **Refactoring Strategy**: "Twin Engines" (Side-by-side build) is safer than in-place refactoring for critical core logic.
- **Strategy Pattern**: Essential for supporting Multiple Drivers (`MysqlDriver`, `DumpDriver`) transparently behind `IDatabaseDriver`.
- **Offline Comparison**: `DumpDriver` + `ComparatorService` allows comparing large SQL dumps efficiently without a running database.

---

## Design Patterns in Use

- **Strategy**: Database drivers (MySQL, Dump)
- **Factory**: `DriverModule` (`useFactory`), `ConnectionFactory.create(config)`
- **Singleton**: Connection pools, Logger
- **Observer**: Migration progress, long operations
- **Dependency Injection**: Framework (Core)

---

## 📂 Key Reference Files

| File                                  | Purpose                       |
| ------------------------------------- | ----------------------------- |
| `ai/the-flow.md`                      | AI setup & workflow guidebook |
| `plans/ARCHITECTURE.md`               | Storage strategy              |
| `plans/MAIN_PLAN.md`                  | 2026 roadmap                  |
| `plans/core/CORE_IMPROVEMENT_PLAN.md` | Core engine plan              |
| `plans/QUALITY_CONTROL_PLAN.md`       | Testing strategy              |
| `plans/core/CORE_PARITY_MAP.md`       | Legacy vs Nest parity status  |
| `.cursorrules`                        | Full AI rules & safety checks |

---

## 📅 Session Log

| Date       | Session Summary                                                                                                                                                                                                                                                                                                                                                    |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2026-01-26 | AI folder structure initialized with full context from AI.md, .cursorrules, and plans/                                                                                                                                                                                                                                                                             |
| 2026-01-26 | Implemented dump comparison Phase 2: added `isTargetDump` guard with toast to `openBatchMigrateModal()`, added i18n (EN/VI)                                                                                                                                                                                                                                        |
| 2026-01-27 | Fixed `DumpDriver` trigger parsing, added bulk actions to global templates, and verified via E2E/Unit tests.                                                                                                                                                                                                                                                       |
| 2026-01-27 | Resolved Connection Duplication bug via `initPromise` store guards and explicit project targeting in `addConnection`.                                                                                                                                                                                                                                              |
| 2026-01-27 | Analyzed connection duplication & project isolation feedback. Updated PLAN.md with 3-phase fix: Deduplication, Isolation, UI Refinement.                                                                                                                                                                                                                           |
| 2026-01-29 | **Framework Migration**: Initialized `core-nest` with "Twin Engine" strategy. Ported `DDLParser`, implemented `MysqlDriver` & `DumpDriver`.                                                                                                                                                                                                                           |
| 2026-01-29 | **Core Logic**: Implemented `ComparatorService` & `MigratorService` for Tables. Verified successfully on real-world SQL dumps.                                                                                                                                                                                                                                     |
| 2026-01-29 | **Full Parity**: Fixed ESLint, ported CLI commands (`generate`, `helper`), and extended comparator to support Views, Procs, and Triggers.                                                                                                                                                                                                                          |
| 2026-02-04 | **Restricted User Flow**: Implemented `generateUserSetupScript` in `core` (Strategy pattern) and exposed via IPC/Preload. Refactored UI to fetch script from backend for transparency and security-first UX. Fixed SQL syntax for MySQL grants.                                                                                                                    |
| 2026-02-04 | **UI/UX & i18n**: Completed comprehensive i18n overhaul for `Dashboard.vue`, `ProjectSettings.vue`, and `GlobalSchemaView.vue`. Standardized terminology (Project -> Base in Vietnamese). Polished Settings layout with dynamic headers.                                                                                                                           |
| 2026-02-04 | **Architecture Planning**: Initiated "Inherit & Protect" Connection Model. Decided to move all security/infrastructure config (Host, User, Pass, SSH) to Global Level (Templates) and enforce inheritance at Project Level.                                                                                                                                        |
| 2026-02-23 | **CLI Decoupling & Playground**: Decoupled CLI (`nest-commander`) from `@the-andb/core` into `@the-andb/cli` to enforce architectural boundaries. Implemented `andb playground` for local schema diffing. Fixed edge cases in diff engine (reversed Desired/Current schemas, ignored implicit `USING BTREE` in indexes) and added comprehensive integration tests. |
| 2026-03-04 | **The \"Roasting\" Session**: Performed a critical UX and technical debt audit. Identified \"Sidebar Bloat\" as a major DOM performance bottleneck. Implemented **Sidebar Depth Optimization** (limiting tree to category level). Planned the \"Specialized Orchestrators\" refactor for `andb-core`.                                                              |
| 2026-03-04 | **Core Safety & Orchestration Refactor**: Implemented `SafetyReport` engine (SAFE/WARNING/CRITICAL classification) in `MigratorService`. Refactored `OrchestrationService` to pure dispatcher. Relocated `testConnection` to `SecurityOrchestrator`. Enhanced `SchemaOrchestrator` with structured dry-run and decomposed migration logic. 17/17 unit tests pass.  |
| 2026-03-04 | **Guard Plan Integration**: Adopted strategic repositioning from "DB Compare Tool" → "Production Safety System" (ADR-010). Integrated `guard.plan.md` into `MAIN_PLAN.md` and aligned Phase 3 with Drift Detection + Deployment Guard goals.                                                                                                                       |
| 2026-03-11 | **Go to Definition & Telemetry**: Implemented Cmd/Ctrl+Click navigation for SQL identifiers across all viewers (`DDLViewer`, `MirrorDiffView`, `SchemaTreeMode`, `DDLDetailModal`). Centralized highlighting logic in `navigation.ts` with Regex caching. Disabled local PostHog telemetry to prevent CSP errors in dev.                                            |
| 2026-03-11 | **Stable Release v4.0.0 (The Andb)**: Officially transitioned from Beta to Stable. Bumped all package versions (@the-andb/core/cli/mcp to 4.0.0, desktop to 3.1.0, www to 1.1.0). Finalized branding as **The Andb**. Published stable Core/CLI to NPM. Successfully built and released Desktop v3.1.0 to GitHub. Updated all internal documentation and synced all repositories. |
