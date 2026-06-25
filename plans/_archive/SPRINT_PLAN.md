# 📋 Sprint Plan — Ship in 14 Days

> **Sprint Goal:** Make `andb` usable by 1 external developer.
> **Deadline:** Mar 10, 2026
> **Rule:** No feature creep. Only these 8 items.

---

## 🎯 Sprint Items

### 1. ✅ Fix 3 Critical Engine Bugs (DONE — Feb 24)

- [x] **BUG-001**: `AFTER \`FIRST\``→`FIRST` keyword (`comparator.service.ts`)
- [x] **BUG-002**: FULLTEXT KEY parsed as column → added to index detection (`parser.service.ts`)
- [x] **BUG-003**: FK DROP+ADD same name → split into 2 ALTER statements (`mysql.migrator.ts`)

**Result:** 24/24 sandbox + 32/32 E2E = **56/56 tests pass**.

---

### 1b. ✅ Post-Roast UX & Stability (DONE — Mar 04)

- [x] **UX-001**: **Sidebar Depth Optimization** (Stopped rendering individual object leaves to fix DOM bloat).
- [x] **FIX-001**: Resolved `activePair` redeclaration and template nesting errors in `Sidebar.vue`.
- [x] **PERF-001**: Reduced sidebar DOM load by ~80% for large schemas.

---

### 2. ✅ CLI Exit Codes (DONE — Mar 04)

- [x] Exit 0: No schema differences detected
- [x] Exit 1: Differences detected (migration available)
- [x] Exit 2: Destructive changes detected (DROP TABLE/COLUMN)

**Why:** CI pipelines gate on exit codes. Without this, `andb compare` is unusable in CI.

---

### 3. JSON Output Mode

- [ ] `andb compare --format json` outputs structured diff
- [ ] Schema: `{ hasChanges, destructive, operations[], alterSQL[] }`
- [ ] Human-readable remains default (`--format text`)

---

### 4. ✅ Destructive Change Warning (DONE — Mar 04)

- [x] Detect DROP TABLE in diff operations
- [x] Detect DROP COLUMN in diff operations
- [x] Print SafetyReport with CRITICAL/WARNING/SAFE classification to stderr
- [x] Set exit code 2 when destructive ops found
- [x] Added `--dry-run` flag to `andb migrate` for preview-only mode

---

### 5. Auto Backup Before Apply

- [ ] `andb migrate --backup` runs `mysqldump` on affected tables before ALTER
- [ ] Backup saved to `./andb-backups/<timestamp>/` as `.sql` files
- [ ] Print backup location before proceeding
- [ ] Backup is opt-in (Phase 2: make it default)

---

### 6. Expose DB ↔ DB Compare CLI

- [ ] `andb compare --source-db <config> --target-db <config>`
- [ ] Reuse existing `compareSchema()` from Core
- [ ] Config: `--host`, `--port`, `--user`, `--password`, `--database`

**Why:** This is the #1 marketing feature. "Compare two live databases."

---

### 7. README: 5-Minute Quickstart

- [ ] Install section (`npm install -g @the-andb/cli` or Docker)
- [ ] First diff in 3 commands
- [ ] Show JSON output example
- [ ] Show CI usage example
- [ ] Known limitations section

---

### 8. Find 3 Beta Users

- [ ] Post on dev community (Reddit r/mysql, Discord, dev.to)
- [ ] Ask 3 contacts to try on their staging DB
- [ ] Document feedback

---

## 📅 History

| Date   | Event                                                    |
| :----- | :------------------------------------------------------- |
| Apr 22 | Monorepo bumped to v4.0.0. AI DBA Assistant integrated.  |
| Apr 22 | Desktop UI stabilized, IPC Deadlocks & Dogfooding fixed. |
| Mar 04 | Core Safety & Orchestration refactor complete. 17 tests. |
| Mar 04 | Guard Plan (ADR-010) integrated into roadmap.            |
| Feb 24 | Sprint defined. 53 E2E+sandbox tests green.              |
| Feb 24 | Production-ready checklist created and refined.          |
| Feb 23 | Deep scenario matrix (17 new scenarios) + sandbox layer. |
| Feb 05 | SSH Tunneling merged to Core.                            |
| Feb 03 | Monorepo unified, Phase 6 (SCA) complete.                |
