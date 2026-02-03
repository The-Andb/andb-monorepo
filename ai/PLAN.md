# 📋 The Andb - Current Plan

> Living document - Planner role

---

## 🎯 Current Task: NestJS Refactor (Twin Engine Strategy)

**Goal:** Rebuild `@the-andb/core` using **NestJS** and **TypeScript** (MySQL Only for now).

**Strategy:** "Twin Engines" - Build `core-nest` side-by-side with `core` without disrupting the legacy engine until parity is reached.

**Priority:** High (Foundation for Phase 3)

---

## 📊 Status

| Phase          | Status     | Notes                                                         |
| -------------- | ---------- | ------------------------------------------------------------- |
| Analysis       | ✅ Done    | Architecture defined (ADR-003, ADR-004)                       |
| Planning       | ✅ Done    | Master plan created                                           |
| Infrastructure | ✅ Done    | Phase 1 Complete. ESLint & Linting added.                     |
| Interfaces     | ✅ Done    | Phase 2 Complete (Parser, Interfaces)                         |
| Driver Logic   | ✅ Done    | Phase 3 Complete (Drivers + Dump + Live Test)                 |
| Logic Engines  | ✅ Done    | Phase 4 Complete. Expanded to all DDL types.                  |
| CLI Features   | ✅ Done    | Phase 4.6: Ported `export`, `compare`, `migrate` & Reporting. |
| Switchover     | 🚀 Running | Phase 5 (Bridge & UI Integration).                            |
| Hardening      | ⏳ Pending | Phase 6 & 7 (Blue/Green & Topological Sort).                  |

---

## 📝 Task Breakdown

### Phase 4.6: Main CLI Commands (✅ Done)

- [x] **4.6.1: `ExportCommand`** (Introspection -> JSON/SQL)
- [x] **4.6.2: `CompareCommand`** (Comparison -> Report)
- [x] **4.6.3: `MigrateCommand`** (Execution)
- [x] **4.6.4: HTML Report Generator** (Premium templates)

### Phase 5: Switchover & Integration (🚀 Running)

- [x] **5.1: E2E Testing Framework** - Verify `core-nest` logic parity.
- [x] **5.2: CoreBridge Implementation**
  - [x] Create `CoreBridge` singleton in `@the-andb/core`.
  - [x] Implement `init()` with explicit `userDataPath` for storage isolation.
  - [x] Map legacy `Container` methods to NestJS services (Container Polyfill).
- [x] **5.3: Desktop (Electron) Refactor**
  - [x] Unify CLI entry point to use `nest-commander`
  - [x] Validate Sidebar schema loading via `SQLiteStorage`.
- [x] **5.4: CLI Unified Interface**
  - [x] Implement `InitCommand` in `@the-andb/core`.
  - [x] Move `andb-cli` to use `nest-commander` with `AppModule`.
  - [x] Deprecate old `andb.js` wrapper logic.
- [x] **5.5: Archive Legacy Core**
  - [x] Push all changes in `andb-core-legacy` and `andb-desktop-legacy` to remote.
  - [x] Move folders to `legacy/` internal storage.
  - [x] Remove legacy packages from root `package.json` workspaces.

### Phase 6: Advanced Deployment (⏳ Backlog)

- [ ] **6.1: Blue/Green Deployment Strategy**
  - [ ] Implement Shadow Table creation logic.
  - [ ] Atomic rename/swap mechanism.
  - [ ] Safe-rollback for failed DDL transitions.
- [ ] **6.2: Pre-flight Safety Checks**
  - [ ] Replication lag detection.
  - [ ] Large table DDL warning (Online DDL detection).

### Phase 7: Dependency Intelligence (⏳ Backlog)

- [ ] **7.1: Topological Sort Engine**
  - [ ] Build DDL dependency graph (Foreign Keys, View base tables).
  - [ ] Auto-order migration scripts to prevent "missing reference" errors.
- [ ] **7.2: Cross-connection Validation**
  - [ ] Verify target server version compatibility.

---

## 📅 History

- **Feb 02 (10:45)**: Expanded Plan with detailed Phase 5-7 tasks based on System Audit.
- **Jan 29 (12:05)**: Standardized ESLint config and fixed all lint errors to improve dev experience.
- **Jan 29 (11:55)**: Ported `generate` and `helper` commands. Verified script generation in `package.json`.
- **Jan 29 (11:43)**: Added Phase 4.5 for CLI Generator parity.
- **Jan 29 (11:32)**: Verified Real World Dump Comparison (f1 vs f2).
