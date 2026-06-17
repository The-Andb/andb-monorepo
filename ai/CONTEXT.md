# 📌 TheAndb - AI Context

> **Rules for AI:**
>
> - Always read CONTEXT.md, **RULES.md** and PLAN.md first
> - Do NOT write code unless explicitly asked
> - Prefer small, reviewable changes
> - Any architecture change must be written to DECISIONS.md
> - End each session by updating MEMORY.md

---

## 🎯 Project Overview

**TheAndb** — Intelligent database orchestration ecosystem for schema comparison, synchronization, and DDL lifecycle management.

**Mission:** Build the definitive open-source native Database Orchestration ecosystem, bridging the gap between personal tooling and enterprise CI/CD safety rails.

**Current Status:** Phase 3 (Expansion) — Stable Release v4.0.0 & Advanced Features

### Licensing

- **Open Core Engine**: `@the-andb/core`, `@the-andb/cli`, and `@the-andb/mcp` are licensed under **AGPL-3.0**.
- **Desktop UI**: `andb-desktop` is **Proprietary** (Closed Source).
- **Privacy Focus**: Zero-Cloud, local-first commitment across all tiers.

---

## 🏗️ Package Structure (Monorepo)

| Package             | Role                             | Storage       |
| ------------------- | -------------------------------- | ------------- |
| `@the-andb/core`    | Pure business logic, stateless   | Agnostic      |
| `@the-andb/desktop` | Electron + Vue 3 desktop         | SQLiteStorage |
| `@the-andb/cli`     | Terminal interface               | FileStorage   |
| `@the-andb/mcp`     | MCP Protocol adapter             | —             |
| `andb-www`          | Open Source Storytelling Landing | —             |

**Core Principle:** All logic in `core`. UI/CLI are adapters only.

---

## 🛠️ Tech Stack

| Layer   | Technology                                                        |
| ------- | ----------------------------------------------------------------- |
| Core    | Node.js (CommonJS), JS/TS                                         |
| UI      | Electron, Vue 3 (Composition API), TypeScript, Pinia, Tailwind v3 |
| Storage | better-sqlite3 (cache), electron-store (prefs)                    |
| Drivers | mysql2, ssh2                                                      |
| Build   | Vite, Electron Builder                                            |

---

## ⚠️ Critical Safety Rules

> **Priority:** SAFETY > CORRECTNESS > ARCHITECTURE > FEATURES > SPEED

### DDL & MySQL

- NEVER promise rollback for DDL (implicit commit)
- Use Virtual/Shadow Dry Run instead
- ALWAYS use MySQL advisory locks (`GET_LOCK`)
- NEVER use file-based locks
- Pre-flight checks REQUIRED:
  - Replication lag
  - Long-running queries
  - Disk space

### Schema Intelligence

- Diffing MUST be semantic/AST-based
- Text-based diffing NOT acceptable

### Database Strategy

- **Deep before Wide** — Master MySQL fully before PostgreSQL

---

## 🏛️ Architecture Rules

1. **Layering**
   - All business logic → `@the-andb/core`
   - UI layer → Presentation + IPC only
   - No domain logic in Vue components
2. **Driver Abstraction**
   - Database logic → `core/src/drivers`
   - Instantiate via `ConnectionFactory`
   - UI never imports drivers directly
3. **IPC Boundary**
   - Renderer ≠ Node.js APIs
   - All access via preload scripts + IPC handlers

4. **Service Container**
   - Core services via `Container`
   - No manual instantiation outside container

---

## 📐 Design Patterns (Mandatory)

| Pattern   | Use Case                           |
| --------- | ---------------------------------- |
| Strategy  | Database drivers                   |
| Factory   | `ConnectionFactory.create(config)` |
| Singleton | Connection pools, Logger           |
| Observer  | Migration progress, long ops       |

---

## 📝 Coding Rules

### FORBIDDEN

- `console.log` in core
- Spawning core as subprocess
- Hardcoding database drivers
- Bypassing driver interfaces

### Standards

- **TypeScript** required for UI + new core
- **Vue**: `<script setup lang="ts">`, Composition API only
- **Styling**: Tailwind utilities, custom CSS in `index.css` only
- **i18n**: All text localized
- **Naming**: Components (`PascalCase`), functions (`camelCase`), CSS (`kebab-case`)

### Error Handling

- Do NOT throw for expected business errors
- Use Result-style: `{ success: boolean, data?, error? }`
- Separate system errors from user-facing errors

---

## 💾 Storage Strategy

| Type          | Source of Truth          | Ideal For               |
| ------------- | ------------------------ | ----------------------- |
| FileStorage   | File system (`.sql`)     | CLI, CI/CD              |
| SQLiteStorage | Local SQLite (`andb.db`) | Electron (5000+ tables) |
| HybridStorage | Dual (SQLite + Files)    | Pro (Git + Performance) |

---

## 📊 Roadmap 2026

| Phase   | Focus                              | Timeline         |
| ------- | ---------------------------------- | ---------------- |
| Phase 1 | Foundation                         | ✅ Done          |
| Phase 2 | MySQL Deep Dive + Core Refactor    | ✅ Done (v4.0.0) |
| Phase 3 | Stable Release & Advanced Features | Mar 2026         |
| Phase 4 | Team Features & Drift Detection    | Apr+ 2026        |

---

## 📂 Key Directories

```
/core          → Engine, drivers, services
/ui            → Vue app, Electron
/cli           → CLI commands
/ai            → AI workspace (this folder)
/plans         → Development plans & strategies
/.agent        → Agent configurations & skills
```

---

## 📚 Reference Documents

- `ai/the-flow.md` — AI setup & workflow guidebook
- `plans/ARCHITECTURE.md` — Storage strategy & schema
- `plans/MAIN_PLAN.md` — Executive roadmap
- `plans/QUALITY_CONTROL_PLAN.md` — Testing strategy
- `plans/core/CORE_IMPROVEMENT_PLAN.md` — Core engine roadmap
- `ai/FAQ.md` — FAQ & Logical Behaviors (symlinked to andb-www docs)
