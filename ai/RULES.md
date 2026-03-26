# 🔒 RULES — Kỷ Luật Thép

> ⚠️ **BẮT BUỘC ĐỌC** trước mỗi phiên làm việc.
> Vi phạm = revert toàn bộ, không thảo luận.

---

## Bước 0: Trước khi code

1. Đọc `CONTEXT.md` → hiểu project
2. Đọc `RULES.md` (file này) → hiểu luật
3. Đọc agent file tương ứng (`agents/implementer-*.md`) → hiểu boundary
4. Đọc `DECISIONS.md` → hiểu precedent
5. Đọc `ai/SYSTEM_DESIGN.md` → hiểu architecture (Meat vs Bones)
6. **Discuss trước, code sau** — không bao giờ nhảy thẳng vào code

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

## 4. Open Core & Hybrid Licensing

```
[AGPL-3.0] @the-andb/core (andb-core)   ↔   [Proprietary] @the-andb/desktop (andb-desktop)
```
- **License Hybrid**: Core engine, CLI, and MCP layer are **AGPL-3.0** (Open Source). Desktop is **Proprietary** (Closed source, free for individual follow-up).
- **Desktop Priority**: Desktop is the flagship product, protected to ensure project sustainability.
- **Bundled Delivery**: App Desktop khi build phải chứa sẵn mọi công cụ (Core, CLI, MCP) bản mới nhất.
- **Separation of Concerns**: Dù bundled, nhưng logic DB vẫn nằm ở Core, logic UI nằm ở Desktop.
- **Web Presence Priority**: Trang web `andb-www` phải tuyệt đối trung thành với format "Technical Storytelling". KHÔNG nhét các bảng giá Pricing thương mại hay Marketing rác vào che lấp tính cách Open Source của Engine.
- **System Design**: Xem chi tiết tại [ai/SYSTEM_DESIGN.md](file:///Volumes/FlexibleWorkplace/The-Andb/ai/SYSTEM_DESIGN.md).

---

## Tham khảo chi tiết

| Chủ đề                 | File                                  |
| ---------------------- | ------------------------------------- |
| System Design          | `ai/SYSTEM_DESIGN.md`                 |
| Architecture & Storage | `plans/ARCHITECTURE.md`               |
| Schema Conflict Rules  | `plans/core/SCHEMA_CONFLICT_RULES.md` |
| Core Engine Rules      | `ai/agents/implementer-core.md`       |
| Desktop Rules          | `ai/agents/implementer-desktop.md`    |
| Licensing Strategy     | `ai/DECISIONS.md#adr-012`             |
| Safety & Coding        | `ai/CONTEXT.md`                       |
