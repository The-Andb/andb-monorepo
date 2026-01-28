# 📋 The Andb - Current Plan

> Living document - Planner role

---

## 🎯 Current Task: Refactor "Fat" Components (Composable Pattern)

**Goal:** Refactor logic-heavy Vue components (`Compare.vue`, `GlobalSchemaView.vue`) into reusable, testable **Composables**. Align with "Thin Components, Fat Composables".

**Priority**: High

---

## 📊 Status

| Phase          | Status         | Notes                                        |
| -------------- | -------------- | -------------------------------------------- |
| Analysis       | ✅ Done        | Identified `Compare.vue` (~1400 lines) as P0 |
| Planning       | ✅ Done        | Strategy defined                             |
| Implementation | 🚧 In Progress | Phase 1 (Compare.vue) starting               |
| Review         | ⏳ Pending     |                                              |

---

## 📝 Task Breakdown

### Phase 1: The "Compare" Review (Highest Impact)

> Focus on extracting logic from `Compare.vue`.

- [ ] **1.1: Create `useCompareCore`**
  - Move API calls (`invoke('compare_schemas')`, etc.) here.
  - Handle loading states (`isComparing`, `loading`).
  - Manage raw `diff` result data.
- [ ] **1.2: Create `useCompareState`**
  - Manage UI state: `viewMode` (tree/list), `filterType`, `searchQuery`.
  - Handle selection logic.
- [ ] **1.3: Refactor `Compare.vue`**
  - Replace internal methods with updating composables.
  - Keep only layout and event binding in the `.vue` file.
  - **Goal:** Reduce LOC to < 500.

### Phase 2: Schema & Sidebar Optimization (Follow-up)

- [ ] **2.1: Create `useSchemaExplorer`** (for `GlobalSchemaView.vue`)
- [ ] **2.2: Enhance `useProjectNavigation`** (for `Sidebar.vue`)

### Phase 3: Testing & Validation

- [ ] **3.1: Unit Tests for Composables**

---

## ⚠️ Risks & Unknowns

| Risk                         | Impact | Mitigation                                      |
| ---------------------------- | ------ | ----------------------------------------------- |
| Regression in Compare Logic  | High   | Keep original component backed up or use git    |
| State synchronization issues | Medium | Define strict ownership of state in composables |

---

## 📅 History

### Previous Task: Fix Connection Management (Jan 2026)

| Phase          | Status  | Notes                                   |
| -------------- | ------- | --------------------------------------- |
| Authentication | ✅ Done | Deduplication & Cleanup implemented     |
| Isolation      | ✅ Done | Sync pairs scoped to project            |
| UI Fixes       | ✅ Done | Dump connections "Test" button disabled |

### Previous Task: Hoàn Thiện Dump Comparison (Jan 2026)

| Phase                    | Status  | Notes                                               |
| ------------------------ | ------- | --------------------------------------------------- |
| Core - DBA Restrictions  | ✅ Done | `MigratorService` guards, `DumpDriver` parser fixes |
| UI - Visual Restrictions | ✅ Done | Disabled buttons, "STATIC" badge, Toast warnings    |
