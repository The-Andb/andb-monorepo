# 📌 AI SETUP – FILE NHẮC VIỆC (DÀNH CHO DEV)

> Mục tiêu: tạo **folder AI + workflow multi-agent** một cách từ từ, thực dụng, không overkill.
> Quy tắc: **xong bước nào, dùng được bước đó**.

---

## 🧱 STEP 0 – TƯ DUY CHUẨN (đọc trước khi làm)

- AI = worker, không phải chatbot
- Mọi thứ quan trọng **phải nằm trong file**, không nằm trong chat
- Không làm multi-agent nếu chưa có planning

---

## 🧱 STEP 1 – TẠO FOLDER AI (BẮT BUỘC)

### ✅ Việc cần làm

- [ ] Tạo folder `/ai` ở root project
- [ ] Commit folder này ngay (để AI coi như “workspace chính thức”)

### 📂 Cấu trúc tối thiểu

```
/ai
 ├─ CONTEXT.md     # Bối cảnh dự án, kiến trúc, tech stack
 ├─ PLAN.md        # Kế hoạch hiện tại (living document)
 ├─ TODO.md        # Việc cần làm, task nhỏ
 ├─ DECISIONS.md   # Các quyết định quan trọng (và lý do)
 └─ MEMORY.md      # Trí nhớ dài hạn cho AI
```

---

## 🧱 STEP 2 – ĐỊNH NGHĨA LUẬT LÀM VIỆC CHO AI

### ✅ Việc cần làm

- [ ] Ghi rules này vào đầu CONTEXT.md

### 📜 Rules chuẩn

```
Rules for AI:
- Always read CONTEXT.md and PLAN.md first
- Do NOT write code unless explicitly asked
- Prefer small, reviewable changes
- Any architecture change must be written to DECISIONS.md
- End each session by updating MEMORY.md
```

---

## 🧱 STEP 3 – TẠO MEMORY (CHỐNG NÃO CÁ VÀNG)

### ✅ Việc cần làm

- [ ] Sau mỗi session, yêu cầu AI cập nhật MEMORY.md

### 🧠 MEMORY.md chỉ nên chứa

- Kiến trúc tổng thể
- Coding conventions
- Những approach đã thử và **bị loại** (rất quan trọng)
- Những điều AI cần nhớ cho các lần sau

---

## 🧱 STEP 4 – CHUẨN BỊ MULTI-AGENT (CHƯA CẦN TOOL)

### 📂 Tạo folder agent

```
/agents
 ├─ planner.md
 ├─ implementer.md
 └─ reviewer.md
```

---

## 🤖 AGENT: PLANNER

**File:** `agents/planner.md`

```
Role: Planner
You never write code.
Your responsibilities:
- Break down tasks
- Update PLAN.md
- Identify risks and unknowns
- Ask clarification questions
```

---

## 🤖 AGENT: IMPLEMENTER

**File:** `agents/implementer.md`

```
Role: Implementer
You write code strictly following PLAN.md.
Rules:
- No architectural changes
- Small commits mindset
- Ask if anything is unclear
```

---

## 🤖 AGENT: REVIEWER

**File:** `agents/reviewer.md`

```
Role: Reviewer
You never add new features.
You only:
- Review logic
- Find bugs and edge cases
- Suggest simplifications
```

---

## 🧱 STEP 5 – WORKFLOW CHUẨN (DÙNG HÀNG NGÀY)

### 🔁 Luồng làm việc

1. Giao task cho **Planner**
2. Planner cập nhật PLAN.md
3. Review kế hoạch (con người)
4. Giao cho **Implementer** viết code
5. Giao cho **Reviewer** soi lại
6. Cập nhật MEMORY.md

---

## 🚫 NHỮNG THỨ CHƯA CẦN LÀM (ĐỪNG HAM)

- ❌ MCP
- ❌ claude-flow
- ❌ swarm agent
- ❌ automation CI bằng AI

👉 Chỉ làm khi: codebase lớn + làm việc nhiều tuần liên tục

---

## ✅ CHECKLIST NHANH

- [ ] Có folder /ai
- [ ] Có PLAN.md & DECISIONS.md
- [ ] AI làm việc qua file, không chat mồm
- [ ] Có MEMORY.md cập nhật đều
- [ ] Multi-agent nhưng **chưa cần framework**

---

> Nếu đọc tới đây mà thấy nhẹ đầu → đang đi đúng đường 😄
