# 📋 The Andb - Current Plan

> Living document - Planner role

---

## 🎯 Current Task: NestJS Refactor (Twin Engine Strategy)

**Goal:** Rebuild `@the-andb/core` using **NestJS** and **TypeScript** (MySQL Only for now).

**Strategy:** "Twin Engines" - Build `core-nest` side-by-side with `core` without disrupting the legacy engine until parity is reached.

**Priority:** High (Foundation for Phase 3)

---

## 📊 Status

| Phase          | Status     | Notes                                                          |
| -------------- | ---------- | -------------------------------------------------------------- |
| Analysis       | ✅ Done    | Architecture defined (ADR-003, ADR-004)                        |
| Planning       | ✅ Done    | Master plan created                                            |
| Infrastructure | ✅ Done    | Phase 1 Complete. ESLint & Linting added.                      |
| Interfaces     | ✅ Done    | Phase 2 Complete (Parser, Interfaces)                          |
| Driver Logic   | ✅ Done    | Phase 3 Complete (Drivers + Dump + Live Test)                  |
| Logic Engines  | ✅ Done    | Phase 4 Complete. Expanded to all DDL types.                   |
| CLI Features   | ✅ Done    | Phase 4.6: Ported `export`, `compare`, `migrate` & Reporting.  |
| Switchover     | ⏳ Pending | Phase 5 (UI Integration) postponed until logic parity reached. |

---

## 📝 Task Breakdown

### Phase 4: Logic Engines & Expansion (🚀 Running)

- [x] **4.1: `ComparatorService` (Tables)**
- [x] **4.2: `MigratorService` (Tables)**
- [x] **4.3: Expand Comparison to non-table DDLs**
  - [x] **4.3.1: Views** (Compare & Generate SQL)
  - [x] **4.3.2: Procedures & Functions**
  - [x] **4.3.3: Triggers** (Specialized logic)
  - [x] **4.3.4: Events**
- [x] **4.4: Real World Dump Test** (`f1.sql` vs `f2.sql`)

- [x] **4.5.1: Port `scripts/generator.js` logic**
- [x] **4.5.2: Port `scripts/helper.js` logic**

### Phase 4.6: Main CLI Commands (✅ Done)

- [x] **4.6.1: `ExportCommand`** (Introspection -> JSON/SQL)
- [x] **4.6.2: `CompareCommand`** (Comparison -> Report)
- [x] **4.6.3: `MigrateCommand`** (Execution)
- [x] **4.6.4: HTML Report Generator**

### Phase 5: Switchover (🚀 Running)

- [x] **5.1: E2E Testing** with `core-nest`.
- [ ] **5.2: Update UI consumer**.
- [ ] **5.3: Archive Legacy Core**.

---

## 📅 History

- **Jan 29 (12:05)**: Standardized ESLint config and fixed all lint errors to improve dev experience.
- **Jan 29 (11:55)**: Ported `generate` and `helper` commands. Verified script generation in `package.json`.
- **Jan 29 (11:43)**: Added Phase 4.5 for CLI Generator parity.
- **Jan 29 (11:32)**: Verified Real World Dump Comparison (f1 vs f2).
