# 🔒 RULES — Kỷ Luật Thép

> ⚠️ **BẮT BUỘC ĐỌC** trước mỗi phiên làm việc.
> Vi phạm = revert toàn bộ, không thảo luận.

---

## Bước 0: Trước khi code

1. Đọc `CONTEXT.md` → hiểu project
2. Đọc `RULES.md` (file này) → hiểu luật
3. Đọc agent file tương ứng (`agents/implementer-*.md`) → hiểu boundary
4. Đọc `DECISIONS.md` → hiểu precedent
5. **Discuss trước, code sau** — không bao giờ nhảy thẳng vào code

---

## 3 Golden Rules

### 1. Export = Online, Compare = Offline

```
EXPORT  → Live DB → Files + SQLite     ✅ kết nối DB
COMPARE → SQLite  → Diff               ❌ KHÔNG kết nối DB
MIGRATE → Live DB → Execute DDL        ✅ kết nối DB đích
```

### 2. No Auto-Fire

```
❌ onMounted(() => testConnections())
❌ watch(pair, () => runComparison())
✅ User click → operation chạy
```

### 3. No DROP Data

```
❌ DROP TABLE, DROP COLUMN trong auto-migrate
✅ DROP VIEW/PROCEDURE/FUNCTION IF EXISTS + CREATE (chỉ logic objects)
```

---

## Tham khảo chi tiết

| Chủ đề                 | File                                  |
| ---------------------- | ------------------------------------- |
| Architecture & Storage | `plans/ARCHITECTURE.md`               |
| Schema Conflict Rules  | `plans/core/SCHEMA_CONFLICT_RULES.md` |
| Core Engine Rules      | `ai/agents/implementer-core.md`       |
| Desktop Rules          | `ai/agents/implementer-desktop.md`    |
| Safety & Coding        | `ai/CONTEXT.md`                       |
| Decisions Log          | `ai/DECISIONS.md`                     |
