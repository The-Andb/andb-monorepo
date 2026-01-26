# 🧠 The Andb - AI Memory

> Long-term memory for AI sessions. Update at end of each session.

---

## 🏗️ Architecture Overview

- **Monorepo**: `core`, `ui`, `cli`, `landing`
- **Core principle**: All logic in `@the-andb/core`
- **UI**: Electron + Vue 3, presentation only
- **Database focus**: MySQL schema comparison & sync
- **Current Phase**: Phase 2 — Hardening (MySQL Deep Dive)

---

## 📐 Coding Conventions

- TypeScript for UI and new core code
- Vue 3 Composition API (`<script setup>`)
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

---

## � Design Patterns in Use

- **Strategy**: Database drivers
- **Factory**: `ConnectionFactory.create(config)`
- **Singleton**: Connection pools, Logger
- **Observer**: Migration progress, long operations

---

## 📂 Key Reference Files

| File                                  | Purpose                       |
| ------------------------------------- | ----------------------------- |
| `plans/ARCHITECTURE.md`               | Storage strategy              |
| `plans/MAIN_PLAN.md`                  | 2026 roadmap                  |
| `plans/core/CORE_IMPROVEMENT_PLAN.md` | Core engine plan              |
| `plans/QUALITY_CONTROL_PLAN.md`       | Testing strategy              |
| `.cursorrules`                        | Full AI rules & safety checks |

---

## 📅 Session Log

| Date       | Session Summary                                                                        |
| ---------- | -------------------------------------------------------------------------------------- |
| 2026-01-26 | AI folder structure initialized with full context from AI.md, .cursorrules, and plans/ |
