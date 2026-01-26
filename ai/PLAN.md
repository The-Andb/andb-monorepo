# 📋 The Andb - Current Plan

> Living document - Planner role

---

## 🎯 Current Task: Hoàn Thiện Dump Comparison

**Goal:** Đảm bảo tính năng so sánh schema từ SQL dump file hoạt động hoàn chỉnh và an toàn.

**Reference:** `compare-dump-enhance.md`

---

## 📊 Status

| Phase          | Status         | Notes                      |
| -------------- | -------------- | -------------------------- |
| Analysis       | ✅ Done        | Reviewed spec, code, tests |
| Planning       | 🔄 In Progress | This document              |
| Implementation | ⏳ Waiting     | Blocked on plan approval   |
| Review         | ⏳ Waiting     | —                          |

---

## 📝 Task Breakdown

### Phase 1: Core - DBA Restrictions ✅ (Already Done)

- [x] `MigratorService`: Throw error nếu target là Dump
- [x] `DumpDriver`: Parser xử lý DELIMITER

### Phase 2: UI - Visual Restrictions ✅

- [x] **2.1** Disable nút "Apply Migration" / "Sync" khi target là dump connection
  - File: `ui/src/views/Compare.vue`
  - Logic: Already has `:disabled="isTargetDump"` on buttons

- [x] **2.2** Hiển thị badge "STATIC" cho dump connections
  - Already exists in Compare.vue (line 14, 17)

- [x] **2.3** Toast warning khi batch migrate vào dump
  - Added guard to `openBatchMigrateModal()`
  - Added i18n: `compare.dumpReadOnly`, `compare.cannotMigrateToDump`

### Phase 3: Parser Robustness ⏳

- [ ] **3.1** Test parser với complex dump files (triggers, procedures với DELIMITER)
  - File: `core/src/drivers/mysql/DumpDriver.js` → `_parseDump()`
  - Existing tests: TBD

- [ ] **3.2** Handle edge cases:
  - Multiple DELIMITER changes
  - Nested procedures
  - UTF-8 special chars

### Phase 4: Testing ⏳

- [ ] **4.1** Enable và fix `dump-ops.e2e.spec.ts`
- [ ] **4.2** Add unit tests cho `DumpDriver._parseDump()`
- [ ] **4.3** Add compare test: Dump vs Live connection

---

## ⚠️ Risks & Unknowns

| Risk                        | Impact | Mitigation                |
| --------------------------- | ------ | ------------------------- |
| Parser fails on complex SQL | High   | Test với real-world dumps |
| UI state not synced         | Medium | Verify reactive bindings  |
| E2E tests flaky             | Low    | Use stable selectors      |

---

## ✅ Clarifications (Resolved)

| Question       | Answer                          |
| -------------- | ------------------------------- |
| Error UX       | **Toast error** — nhẹ nhàng     |
| Cache clearing | **Không cần** — dump là static  |
| Test priority  | **Unit test → Vite test → E2E** |

---

## 🧪 Verification Plan

### Automated Tests

```bash
# Core unit tests
cd core && npm test -- --grep "DumpDriver"

# UI E2E tests
cd ui && npx playwright test dump-ops.e2e.spec.ts --headed
```

### Manual Verification

1. **Tạo dump connection:**
   - Project Settings → Add Connection → Type: Dump
   - Select file `.sql`
   - Verify hiện badge "READ-ONLY"

2. **Compare dump vs live:**
   - Compare View → Select pair (Dump → Live)
   - Verify diff hiển thị đúng
   - Verify nút "Sync" **enabled** (dump is source, live is target)

3. **Compare live vs dump:**
   - Select pair (Live → Dump)
   - Verify nút "Sync" **disabled** với tooltip
   - Click → Verify không có action

---

## 📅 History

| Date       | Update                          |
| ---------- | ------------------------------- |
| 2026-01-26 | Initial plan created by Planner |
