# 🧠 AI DBA SUPER MODE — v3 (Final)

> Schema Review & Diff Intelligence Engine
> **Status**: Ready for Implementation

---

## 🚀 Vision

> Biến mọi developer thành DBA level senior — bằng 1 trigger, multi-step pipeline.

System không chỉ chạy SQL — mà **hiểu được hậu quả của SQL đó trong production**, bao gồm cả rollback strategy.

---

## ⚔️ Problem Statement

- Dev viết migration dựa vào "feeling"
- Review chủ yếu là eyeballing
- Không biết: lock bao lâu? FK ảnh hưởng? Gây downtime?
- **Không có rollback plan** — nếu migration fail, dev chạy bằng cơm

> Deploy DB luôn là một canh bạc.

---

## 💡 Core Idea

> **AI-powered DBA Advisor** (Hybrid: Rule + AI)

**Input:**

- Schema hiện tại (DDL)
- Diff (structured, AST-based)
- **Table metadata** (row count, data_length, index size) — cached
- **Server context** (MySQL version, peak/off-peak flag)

**Output:**

- Risk score + confidence %
- Performance impact + estimated duration
- Hidden side effects (FK graph, locking order)
- Migration strategy (production-grade, multi-step, with batching)
- **Rollback script** (auto-generated)

---

## 🧱 System Architecture

```
┌──────────────────────────────────────────────────┐
│ Step 0: Syntax Validation (reject invalid SQL)   │
└──────────────────┬───────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│ Diff Engine (REUSE existing services)            │
│  • ComparatorService  → ITableDiff               │
│  • SemanticDiffService → ISemanticReport          │
│  • ImpactAnalysisService → ISafetyReport          │
│  → Output: IContextBundle (aggregated)            │
└──────────────────┬───────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│ Context Builder → [Meta-Cache]                   │
│  • Table stats (TTL: 5 min)                      │
│  • FK Graph (TTL: 1 hour)                        │
│  • MySQL version detection                       │
│  → User can "Refresh Stats" to force update      │
└──────────────────┬───────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│ Prompt Builder → [Token Budget Check]            │
│  • Send ISemanticReport (structured, no raw DDL) │
│  • Opt-in: send raw DDL for Deep Mode            │
└──────────────────┬───────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│ AI Provider → [Fallback: Rule-Only if timeout]   │
│  • Tier 1: Gemini Flash / GPT-4o-mini (cheap)    │
│  • Tier 2: Gemini Pro / GPT-4o (complex reviews) │
│  • Tier 3: Ollama local (privacy mode, ≥70B)     │
└──────────────────┬───────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│ Post Processor → [JSON Schema Validator]         │
│  • Cross-check AI claims vs AST facts            │
│  • Discard hallucinated FK/index references      │
└──────────────────┬───────────────────────────────┘
                   ↓
┌──────────────────────────────────────────────────┐
│ Risk Engine (Hybrid) → Final Score               │
└──────────────────┬───────────────────────────────┘
                   ↓
               UI / CLI
```

---

## 🧩 Core Components

### 1. Diff Engine (REUSE, Don't Rebuild)

Tận dụng 3 services sẵn có trong `andb-core`:

| Service                 | Output            | Role                                 |
| ----------------------- | ----------------- | ------------------------------------ |
| `ComparatorService`     | `ITableDiff`      | Structural diff (ADD/DROP/MODIFY)    |
| `SemanticDiffService`   | `ISemanticReport` | Human-readable explanations          |
| `ImpactAnalysisService` | `ISafetyReport`   | SAFE/WARNING/CRITICAL classification |

→ Aggregate thành `IContextBundle` duy nhất cho pipeline.

```typescript
interface IContextBundle {
  diff: ITableDiff;
  semantic: ISemanticReport;
  safety: ISafetyReport;
  meta: ITableMetadata; // from Context Builder
  serverInfo: IServerInfo; // MySQL version, engine
}
```

---

### 2. Context Builder (CRITICAL — 80% Quality)

Cache-first strategy. Không bao giờ query realtime trên mỗi lần review.

| Data           | Source                                | Cache TTL | Fallback                    |
| -------------- | ------------------------------------- | --------- | --------------------------- |
| Row count      | `SHOW TABLE STATUS`                   | 5 min     | `information_schema.TABLES` |
| Data size (MB) | `SHOW TABLE STATUS`                   | 5 min     | estimated from row_count    |
| FK Graph       | `information_schema.KEY_COLUMN_USAGE` | 1 hour    | from exported DDL           |
| Cardinality    | `SHOW INDEX FROM table`               | 30 min    | skip (optional)             |
| MySQL version  | `SELECT VERSION()`                    | session   | config file                 |

**User control**: Nút "Refresh Stats" để force-update cache.

**Locking Order Detection**: Traverse FK graph depth-first để phát hiện circular dependencies và potential deadlock chains.

---

### 3. AI Review Engine

#### 5 Capabilities:

| #   | Capability                  | Example                                                 |
| --- | --------------------------- | ------------------------------------------------------- |
| a   | **Context-aware analysis**  | "Column X là FK của bảng Y → lock cả 2 bảng"            |
| b   | **Performance insight**     | "Full table rebuild ~10M rows, ~5 min on SSD"           |
| c   | **Safety detection**        | Data loss, null violation, constraint break             |
| d   | **Backwards compatibility** | "App code vẫn query column cũ → crash sau rollback"     |
| e   | **Data integrity check**    | "ADD NOT NULL mà không có DEFAULT → existing rows fail" |

---

### 4. Hybrid Risk Engine (Quad-Check)

```
Check 0: Syntax Validation
  └─ Invalid SQL → REJECT immediately

Check 1: AST Rules (Deterministic)
  └─ DROP/TRUNCATE/RENAME → CRITICAL (instant, no AI needed)

Check 2: Meta-Threshold
  └─ data_length > 500MB OR row_count > 5M → flag for Deep Review
  └─ MySQL version < 8.0 + MODIFY COLUMN → flag (no instant DDL)

Check 3: Contextual AI
  └─ Only triggered if Check 1+2 flagged "Non-Trivial"
  └─ Analyze FK side-effects, deadlocks, naming conventions
  └─ Cross-checked against AST to eliminate hallucinations
```

---

### 5. Suggested Migration Strategy (Production-Grade)

Không chỉ cảnh báo — phải **fix**, và fix đúng cách.

#### Example:

❌ User:

```sql
ALTER TABLE users MODIFY email VARCHAR(500);
```

✅ System (production-grade):

```sql
-- Step 0: Backup
CREATE TABLE users_backup_20260327 LIKE users;
INSERT INTO users_backup_20260327 SELECT * FROM users;

-- Step 1: Add new column
ALTER TABLE users ADD COLUMN email_new VARCHAR(500) AFTER email;

-- Step 2: Backfill (batched to avoid lock + binlog overflow)
-- Loop: UPDATE users SET email_new = email WHERE id BETWEEN ? AND ? LIMIT 10000;

-- Step 3: Swap columns
ALTER TABLE users DROP COLUMN email, CHANGE email_new email VARCHAR(500);

-- Step 4: Verify
SELECT COUNT(*) FROM users WHERE email IS NULL;  -- should be 0
```

---

### 6. Output Contract (API Design)

```json
{
  "summary": "High risk migration: full table rebuild on large table",
  "risk_score": 8.7,
  "confidence": 0.85,
  "estimated_duration": "~5 min (10M rows, InnoDB, SSD)",
  "affected_tables": ["users", "orders", "order_items"],
  "mysql_version": "8.0.35",
  "analysis": {
    "performance": ["Full table rebuild (~10M rows, 2.3GB data)"],
    "locking": ["Metadata lock on 'orders' (FK child)", "~3 min lock window"],
    "design": [
      "Column 'usr_id' violates project naming convention (expected: 'user_id')"
    ],
    "compatibility": [
      "Application v3.2 still references 'email' column by old name"
    ],
    "integrity": ["32 rows have NULL email — will fail NOT NULL constraint"]
  },
  "suggestions": [
    {
      "type": "CHECKLIST",
      "steps": [
        "Backup table",
        "Verify disk space (need ~2.3GB)",
        "Schedule off-peak window"
      ]
    },
    {
      "type": "MIGRATION_SCRIPT",
      "steps": ["(batched multi-step script as above)"]
    },
    {
      "type": "ONLINE_TOOL",
      "name": "gh-ost",
      "command": "gh-ost --host=... --table=users --alter='MODIFY email VARCHAR(500)' --execute"
    }
  ],
  "rollback_script": "ALTER TABLE users MODIFY email VARCHAR(255) NOT NULL;"
}
```

---

## ⚙️ Execution Strategy

### Modes

| Mode              | Trigger                      | AI Used?       | Token Cost | Use Case          |
| ----------------- | ---------------------------- | -------------- | ---------- | ----------------- |
| **Auto** (Silent) | Every diff                   | No (Rule-only) | 0          | Quick safety gate |
| **Deep** (Manual) | User clicks "Review with AI" | Yes (Tier 1/2) | ~1K tokens | Pre-deploy review |
| **CI** (Phase 3)  | `andb review --ci`           | Yes            | ~1K tokens | Pipeline gate     |

- **Auto Mode**: Chạy ngầm, chỉ popup nếu Check 1+2 flagged WARNING/CRITICAL.
- **Deep Mode**: Full AI pipeline, gửi prompt, render kết quả trong UI drawer.
- **CI Mode** (Phase 3): `andb review --ci --fail-on=CRITICAL` → JSON output, env var `ANDB_AI_KEY`.

---

## 🔐 Privacy Strategy

| Mode                    | Dữ liệu gửi đi                             | Chất lượng | Target        |
| ----------------------- | ------------------------------------------ | ---------- | ------------- |
| **Cloud AI**            | `ISemanticReport` (structured, no raw DDL) | ★★★★★      | Default       |
| **Cloud AI + Opt-in**   | Raw DDL (user phải bật)                    | ★★★★★      | Power users   |
| **Local (Ollama ≥70B)** | Không gì rời máy                           | ★★★☆☆      | Privacy-first |
| **Self-host**           | Internal API                               | ★★★★☆      | Enterprise    |

> **Mặc định**: Chỉ gửi structured semantic report, KHÔNG gửi raw SQL.
> User phải opt-in để gửi raw DDL cho Deep Mode.

---

## 💰 Monetization

| Tier           | Feature                                              | Limit             |
| -------------- | ---------------------------------------------------- | ----------------- |
| **Free**       | Diff + AST safety (Rule-only)                        | Unlimited         |
| **Pro**        | AI Review (Deep Mode)                                | 100 reviews/month |
| **Team**       | CI Mode + shared review history + naming conventions | Custom            |
| **Enterprise** | Local AI + SSO + audit log + private deployment      | Unlimited         |

---

## 🧨 Pitfalls (Avoid at all cost)

| #   | Pitfall                     | Mitigation                                                                                          |
| --- | --------------------------- | --------------------------------------------------------------------------------------------------- |
| 1   | **Blind trust AI**          | Always show reasoning + AST cross-check                                                             |
| 2   | **Missing context**         | Garbage in → garbage out. Meta-Cache required                                                       |
| 3   | **Text-only UX**            | Attach warnings inline to diff lines                                                                |
| 4   | **AI Hallucination**        | Cross-check AI claims vs AST facts. Discard mismatches                                              |
| 5   | **MySQL version blindness** | Must detect version. MySQL 5.7 vs 8.0 handle ALTER completely differently (instant DDL, online DDL) |

---

## 🏗️ Implementation Phases

### Phase 1: Foundation (v3.4.0)

- [ ] `IContextBundle` interface in `andb-core`
- [ ] `ContextExtractor` service (cache + table stats)
- [ ] `AIProviderAbstraction` (Gemini Flash default)
- [ ] `PostProcessor` with hallucination cross-check
- [ ] CLI: `andb review -s source.sql -t target.sql --ai`
- [ ] E2E tests: mock AI responses

### Phase 2: Desktop Integration (v3.5.0)

- [ ] "Review with AI" button in Compare View
- [ ] AI Review Drawer (inline warnings on diff lines)
- [ ] Settings: API key config, privacy opt-in toggle
- [ ] MCP tool: `review_schema_change`

### Phase 3: CI & Enterprise (v3.6.0)

- [ ] `andb review --ci --fail-on=CRITICAL`
- [ ] Ollama local provider (≥70B)
- [ ] Team dashboard (shared review history)
- [ ] Audit log for Enterprise

---

## 🧠 Philosophy

> "Good developers write queries.
> Great developers understand impact.
> **This system bridges that gap.**"

---

**Ship Phase 1 small. But build the architecture this big.** 🚀
