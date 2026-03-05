# 🚀 The Andb — Beta Launch & Feature Expansion Plan

> **Created:** Feb 27, 2026
> **Objective:** Launch a controlled beta program with feedback loops, while planning two major feature expansions (MCP Server + DB Design Module).

---

## Overview — 5 Pillars

| #   | Pillar                        | Priority   | Effort    | Dependencies                   |
| --- | ----------------------------- | ---------- | --------- | ------------------------------ |
| 1   | **Beta Test Program**         | 🔴 Highest | 1 week    | Publish strategy, Landing page |
| 2   | **Bug Report System**         | 🔴 Highest | 2-3 days  | Beta program                   |
| 3   | **Feature Suggestion System** | 🟡 Medium  | 2-3 days  | Beta program                   |
| 4   | **Power MCP Server**          | 🟡 Medium  | 1-2 weeks | Core engine stable             |
| 5   | **DB Design Module**          | 🟢 Future  | 3-4 weeks | Core + MCP stable              |

---

## 1. Beta Test Program

### Strategy

Two entry points for beta testers:

- **A. Download-first:** User downloads Desktop app → App requires beta email registration on first launch before enabling features
- **B. Sign-up-first:** User registers on `andb.dev/beta` → Receives download link + beta key via email

> **Recommendation:** Strategy A (download-first) has lower friction. User downloads, enters email, gets instant access. No waiting for email.

### Breakdown

1. [ ] **Phase 1: Beta Gate (Desktop App)**
   - [ ] Add "Beta Registration" screen on first launch (before dashboard)
   - [ ] Fields: Email, Name (optional), Company (optional), Use case (dropdown: "Personal", "Startup", "Enterprise")
   - [ ] Store beta registration locally in `electron-store`
   - [ ] API call to backend to register beta tester
   - [ ] On success: unlock the app, show "Welcome to Beta" toast
   - [ ] On subsequent launches: skip registration (already registered)

2. [ ] **Phase 2: Beta Landing Page (`andb.dev/beta`)**
   - [ ] Hero section: "Join the Beta — Help us build the best DB migration tool"
   - [ ] Email signup form with Resend/Mailgun integration
   - [ ] Auto-send welcome email with download links (DMG/EXE/AppImage)
   - [ ] Beta key generation (simple UUID-based, no complex licensing)
   - [ ] Counter: "X developers in the beta"

3. [ ] **Phase 3: Beta Backend (Lightweight API)**
   - [ ] Endpoint: `POST /api/beta/register` → { email, name, useCase }
   - [ ] Endpoint: `GET /api/beta/verify/:key` → { valid: true/false }
   - [ ] Storage: Supabase (free tier) or simple JSON file on Vercel
   - [ ] Rate limiting: 10 req/min per IP
   - [ ] Email delivery: Resend (100 free/day)

### Tech Stack Decision

| Option                | Pros                               | Cons                  | Verdict         |
| --------------------- | ---------------------------------- | --------------------- | --------------- |
| **Supabase + Vercel** | Free tier, Postgres, auth built-in | Another dependency    | ✅ Best for MVP |
| **Firebase**          | Realtime, easy                     | Google lock-in, NoSQL | ❌ Overkill     |
| **Self-hosted**       | Full control                       | Maintenance overhead  | ❌ Too early    |

### Files Affected

- `andb-desktop/electron/main.ts` (beta gate check)
- `andb-desktop/src/views/BetaRegistration.vue` [NEW]
- `andb-desktop/src/composables/useBeta.ts` [NEW]
- `andb-www/` (beta landing page)
- `andb-api/` [NEW package or Vercel serverless]

---

## 2. Bug Report System

### Strategy

In-app bug reporting that captures context automatically. No external tools required for beta phase.

### Breakdown

1. [ ] **Phase 1: In-App Bug Report Button**
   - [ ] Floating "🐛 Report Bug" button in desktop app (bottom-right corner)
   - [ ] Click → Modal with: Title, Description, Steps to reproduce
   - [ ] Auto-capture: App version, OS, Environment count, Last error from console
   - [ ] Screenshot attachment (optional, use `html-to-image` already in deps)
   - [ ] Submit → API call to backend

2. [ ] **Phase 2: Bug Report Backend**
   - [ ] Endpoint: `POST /api/bugs` → { title, description, context, screenshot? }
   - [ ] Storage: GitHub Issues API (auto-create issue with label "beta-bug")
   - [ ] Alternative: Linear API or simple Supabase table
   - [ ] Notification: Slack webhook or email to maintainer

3. [ ] **Phase 3: Bug Report Dashboard (Nice to Have)**
   - [ ] Simple admin page to view/triage bugs
   - [ ] Status tracking: Open → In Progress → Fixed → Deployed

### Auto-Context Capture

```json
{
  "appVersion": "3.0.0",
  "electronVersion": "34.0.0",
  "os": "macOS 15.3 arm64",
  "nodeVersion": "v20.19.3",
  "environments": 3,
  "connections": 5,
  "lastError": "ERR_DLOPEN_FAILED...",
  "timestamp": "2026-02-27T09:00:00Z"
}
```

### Files Affected

- `andb-desktop/src/components/BugReport.vue` [NEW]
- `andb-desktop/src/composables/useBugReport.ts` [NEW]
- `andb-desktop/electron/ipc/bug-report.ts` [NEW]

---

## 3. Feature Suggestion System

### Strategy

Lightweight feature request system integrated into the app. Uses same backend as bug reports but with different categorization.

### Breakdown

1. [ ] **Phase 1: In-App Feature Request**
   - [ ] "💡 Suggest Feature" button next to bug report
   - [ ] Modal with: Title, Description, Category (dropdown)
   - [ ] Categories: "Schema Compare", "Migration", "UI/UX", "CLI", "MCP", "Other"
   - [ ] Optional: Priority vote (Nice to Have / Important / Critical)
   - [ ] Submit → API call

2. [ ] **Phase 2: Public Roadmap (Nice to Have)**
   - [ ] `andb.dev/roadmap` page shows submitted feature requests
   - [ ] Beta users can upvote features
   - [ ] Status: Requested → Planned → In Progress → Shipped
   - [ ] Powered by GitHub Discussions or Canny (free tier)

### Files Affected

- `andb-desktop/src/components/FeatureRequest.vue` [NEW]
- `andb-desktop/src/composables/useFeatureRequest.ts` [NEW]

---

## 4. Power MCP Server

### Current State

`andb-mcp` exists with 7 basic tools (`test_connection`, `list_schema_objects`, `get_object_ddl`, `compare_schema`, `export_schema`, `get_db_status`, `migrate_schema`).

### Vision: "Power MCP" — AI-Native Database Operations

Transform MCP from a simple bridge into a **smart database assistant** that AI agents can use for complex operations.

### Breakdown

1. [ ] **Phase 1: Stability & Reliability**
   - [ ] Fix any existing tool errors/edge cases
   - [ ] Add input validation with Zod schemas
   - [ ] Add timeout handling for long-running operations
   - [ ] Error messages should be AI-friendly (structured, not stack traces)
   - [ ] Add `andb://health` resource for status checks

2. [ ] **Phase 2: Desktop Management Tab (CLI & MCP)**
   - [ ] Build a new tab in the Desktop App (`CLI & MCP`)
   - [ ] **CLI Panel:** Auto-detect if `andb` is in `PATH`. Button to "Install CLI tool" (symlink to binary).
   - [ ] **MCP Panel:** Auto-detect popular AI assistants (Cursor, Cline, Windsurf).
   - [ ] 1-Click Install: Append the MCP config block into the respective editor's `mcp.json` or config file.
   - [ ] Status indicators showing which tools/editors currently have The Andb active.

3. [ ] **Phase 3: Smart Analysis Tools**
   - [ ] `analyze_schema` — Return schema statistics (table count, index coverage, FK graph, column types distribution)
   - [ ] `detect_drift` — Compare two envs and return human-readable drift summary
   - [ ] `suggest_indexes` — Analyze query patterns vs existing indexes (basic heuristic)
   - [ ] `explain_migration` — Given a diff, explain what each ALTER does in plain English
   - [ ] `validate_migration` — Dry-run check: will this migration succeed? (FK deps, data type compat)

4. [ ] **Phase 4: Multi-Step Workflows**
   - [ ] `plan_deployment` — Given src/dest, generate a full migration plan with ordering (FK dependency graph)
   - [ ] `backup_and_migrate` — Atomic: backup → migrate → verify → report
   - [ ] `rollback_migration` — Given a migration ID, generate rollback SQL from snapshots
   - [ ] `compare_all_envs` — Compare DEV→STAGE→PROD in one call, return drift matrix

5. [ ] **Phase 5: Resources & Prompts**
   - [ ] `andb://config` — Expose project config
   - [ ] `andb://schema/{env}/{db}` — Expose full schema as resource
   - [ ] `andb://diff/{src}/{dest}` — Expose latest diff as resource
   - [ ] `andb://history` — Migration history as resource
   - [ ] Built-in prompts: "Review this migration", "Is my schema optimized?", "What changed between DEV and PROD?"

### Files Affected

- `andb-mcp/src/tools/` (new tool handlers)
- `andb-mcp/src/resources/` (new resource handlers)
- `andb-mcp/src/prompts/` [NEW] (prompt templates)
- `andb-core/src/modules/analyzer/` [NEW] (analysis logic)

---

## 5. DB Design Module

### Vision

A **visual database design tool** inside The Andb desktop app. Design schemas visually, generate DDL, and sync with live databases.

### Breakdown

1. [/] **Phase 1: ERD Viewer (Read-Only)**
   - [x] Initial sidebar entry added (hidden by `erDiagram` feature flag)
   - [ ] Parse existing schema from storage → Generate ERD (Entity Relationship Diagram)
   - [ ] Display tables as cards with columns, types, keys
   - [ ] Draw FK relationships as lines between tables
   - [ ] Zoom, pan, drag tables to arrange
   - [ ] Export as PNG/SVG
   - [ ] Tech: Canvas-based (fabric.js or konva.js) or SVG-based (d3.js)

2. [ ] **Phase 2: ERD Editor (Interactive)**
   - [ ] Create new tables visually (click + type)
   - [ ] Add/edit/remove columns inline
   - [ ] Draw FK relationships by dragging between columns
   - [ ] Set column properties: type, nullable, default, auto_increment
   - [ ] Real-time DDL preview panel (shows CREATE TABLE as you design)
   - [ ] Undo/Redo support

3. [ ] **Phase 3: Design → DDL → Migration Pipeline**
   - [ ] "Design" tab generates DDL from visual schema
   - [ ] Compare designed schema vs live database → Generate ALTER statements
   - [ ] Apply designed schema to target environment
   - [ ] Version control for designs (save/load design snapshots)
   - [ ] **DBML Support**: Export visual schema to DBML (Database Markup Language) blueprint
   - [ ] Convert existing live database schema directly to DBML format

4. [ ] **Phase 4: AI-Assisted Design & Advanced DBML (Future)**
   - [ ] MCP tool: `design_schema` — AI generates ERD from natural language
   - [ ] **DBML Editor**: Text-based DBML editor with syntax highlighting that auto-syncs with the visual ERD canvas
   - [ ] "Describe your app" → Auto-generate table structures
   - [ ] Normalization suggestions
   - [ ] Anti-pattern detection (e.g., "this column should be a separate table")

### Tech Stack Decision

| Option         | Pros                      | Cons                     | Verdict     |
| -------------- | ------------------------- | ------------------------ | ----------- |
| **Vue Flow**   | Vue-native, node-based UI | Learning curve           | ✅ Best fit |
| **React Flow** | Most popular              | React in Vue app = messy | ❌          |
| **D3.js**      | Low-level control         | Too much work for MVP    | ❌          |
| **Konva.js**   | Canvas-based, fast        | Not graph-native         | ⚠️ Backup   |

### Files Affected

- `andb-desktop/src/views/DbDesigner.vue` [NEW]
- `andb-desktop/src/components/designer/` [NEW directory]
  - `TableCard.vue`, `ColumnEditor.vue`, `RelationshipLine.vue`
  - `DesignerCanvas.vue`, `DdlPreview.vue`
- `andb-core/src/modules/designer/` [NEW]
  - `designer.service.ts` — Schema to ERD model conversion
  - `ddl-generator.service.ts` — ERD model to DDL generation

---

## 📅 Suggested Timeline

```
Week 1-2:  Beta Program (Gate + Landing + API)
           Bug Report + Feature Suggestion
           ─── Ship Beta v1 ───

Week 3-4:  Power MCP Server (Phase 1-2)
           ERD Viewer (Read-Only)

Week 5-6:  Power MCP Server (Phase 3-4)
           ERD Editor (Interactive)

Week 7-8:  Design → DDL Pipeline
           Public Roadmap
           ─── Ship Beta v2 ───
```

---

## Risks

| Risk                                       | Impact | Mitigation                                       |
| ------------------------------------------ | ------ | ------------------------------------------------ |
| Beta gate adds friction → users bounce     | High   | Make registration < 10 seconds, email-only       |
| Bug reports flood with low-quality noise   | Medium | Auto-context capture reduces need for user input |
| MCP tools are too slow for AI agents       | Medium | Add timeout + streaming for long operations      |
| ERD rendering performance with 100+ tables | High   | Canvas-based renderer, virtual viewport          |
| Scope creep on DB Design Module            | High   | Start with read-only ERD only, iterate           |

---

## Resolved Decisions (Free/Built-in Stack)

- ✅ **Beta backend hosting:** Vercel Serverless + Supabase (Free tier rộng rãi, không tốn công quản lý server).
- ✅ **Email service:** Resend (100 free emails/day - quá đủ cho giai đoạn Beta kín).
- ✅ **Bug tracking destination:** GitHub Issues (Dùng API bắn thẳng report thành issue gắn mác `beta-bug`, free và tập trung).
- ✅ **Feature voting:** GitHub Discussions (Có sẵn, free, user cũng quen workflow của GitHub).
- ✅ **MCP publishing:** npm package (Chuẩn mực, free, dễ tiếp cận nhất cho dev).
- ✅ **ERD library choice:** Vue Flow (Native Vue, open source MIT, phù hợp nhất cho dạng node-based UI).
- ✅ **Beta key enforcement:** Soft gate (Màn hình đăng ký thu thập email để build audience, nhưng nếu lỡ rớt mạng hoặc API lỗi thì vẫn cho vô app dùng, giảm tối đa ma sát).
