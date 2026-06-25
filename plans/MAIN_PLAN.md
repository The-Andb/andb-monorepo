# 🎯 TheAndb — Product Roadmap

**Mission:** A CLI-first MySQL schema diff engine that detects drift and generates deterministic migration scripts with preview and backup.

**Value Prop:** _"Andb detects schema drift automatically and generates deterministic migration scripts with preview and backup — removing manual diff mistakes."_

**Strategic Direction:** Evolving from "DB Compare Tool" → "Production Safety System" — see [guard.plan.md](file:///Volumes/FlexibleWorkplace/The-Andb/plans/guard.plan.md) for the 6-month execution plan.

**Current Status:** Phase 2 → Trustable Product (Safety & Orchestration refactored)

---

## 📊 Product Phases

| Phase       | Name                  | Goal                                            | Status     |
| :---------- | :-------------------- | :---------------------------------------------- | :--------- |
| **Phase 1** | **Provable Engine**   | 1 external dev runs `andb compare` successfully | ✅ Done    |
| **Phase 2** | **Trustable Product** | 1 team uses on staging for 2 weeks, 0 incidents | ✅ Done    |
| **Phase 3** | **Revenue Ready & AI**| 1 paying customer + Stable AI DBA workflows     | ✅ Done    |
| **Phase 4** | **Revenue Ready**     | 1 paying customer                               | 🚧 Active  |

---

## 🔧 Phase 1: Provable Engine (Now → 14 days)

### ✅ Done

- Diff engine deterministic — 32 E2E + 21 sandbox scenarios on Docker MySQL
- No false positives — INT display width, BTREE, column reorder normalization
- Column change detection (type, null, default)
- Index change detection (composite, prefix, unique, fulltext)
- Foreign key change detection (add, drop, cascade change, multi-column)
- CLI non-interactive mode
- SSH tunneling in Core

### 🚨 Must Ship (14-day sprint)

1. Fix 3 engine bugs (AFTER FIRST, FULLTEXT AFTER, FK ordering)
2. CLI exit codes (0=no diff, 1=diff, 2=destructive)
3. JSON output mode (`--format json`)
4. Destructive change warning
5. Auto backup before apply
6. Expose DB ↔ DB compare CLI
7. README: 5-minute quickstart
8. 3 external beta users

### Known Limitations (Document, don't fix)

- Charset / collation change detection
- Engine change detection (InnoDB → MyISAM)
- Multi-table file parsing (only first table)
- Version-comment normalization

---

## 🛡️ Phase 2: Trustable Product

- ✅ SafetyReport Engine — SQL classified as SAFE / WARNING / CRITICAL
- ✅ Structured Dry-run — full preview without DB writes
- ✅ Pure Dispatcher — `OrchestrationService` refactored, `testConnection` relocated
- ✅ **Go to Definition** — Cmd/Ctrl+Click navigation with optimized Regex caching
- ✅ Auto backup before apply (`mysqldump` snapshot)
- ✅ `⚠️ Destructive change detected` warnings in UI
- ✅ DB ↔ SQL file comparison
- ✅ Clean structured CLI output (no Framework debug noise)
- ✅ MySQL 5.7 compatibility testing
- ✅ Internal Schema Orchestrator (Dogfooding) stabilized

---

## 🤖 Phase 2.5: AI Integration (v4.0.0 -> v4.0.4)

- ✅ Monorepo version bumped to v4.0.4
- ✅ AI DBA Assistant Panel integration
- ✅ Context-aware Schema/Code Ask AI
- ✅ SQLite Chat History Persistence
- ✅ Global UI/UX Stabilization (Sidebar scaling, Layout skew fixed)
- ✅ Beta Program Registration implemented
- ✅ Web portal launched at andb.dev

---

## 💰 Phase 3: Revenue Ready (aligned with [guard.plan.md](file:///Volumes/FlexibleWorkplace/The-Andb/plans/guard.plan.md))

- Drift Detection Agent (CLI scheduler → cloud snapshots)
- Deployment Guard (CI plugin — GitHub Actions first)
- Docker image (GHCR / DockerHub)
- GitHub Actions + GitLab CI examples
- License via Keygen.sh or LemonSqueezy (NOT in-house)
- 14-day trial
- Landing page with Get Started flow
- 1 case study / battle story

---

## ❌ Explicitly Delayed

| Item                     | Reason                                   |
| :----------------------- | :--------------------------------------- |
| PostgreSQL               | After MySQL rock solid                   |
| Auto rollback generation | Backup + manual revert enough            |
| Policy engine            | Warning enough for Phase 2               |
| Environment tagging      | User manages via config                  |
| Team licenses            | Sell individual first                    |
| AST-based parsing        | Current regex/semantic parser sufficient |
| Telemetry                | No users = nothing to collect            |

---

## 📦 Package Structure

| Package          | Role                                    | Status    |
| :--------------- | :-------------------------------------- | :-------- |
| `@the-andb/core` | Pure business logic (Framework, mysql2) | ✅ Active |
| `@the-andb/cli`  | Terminal interface (nest-commander)     | ✅ Active |
| `@the-andb/test` | E2E + Sandbox test suite (Jest)         | ✅ Active |
| `andb-desktop`   | Electron + Vue 3 desktop app            | ✅ Built  |
| `andb-www`       | Landing page                            | ⏳ Next   |

**Core Principle:** All logic in `core`. CLI/UI are adapters.
