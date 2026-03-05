# The Andb — Production Readiness Checklist

> **This is a serious product, not a side project.**

> **Target user**: Solo dev / small team managing MySQL schemas.
> **Value prop**: _"Andb detects schema drift automatically and generates deterministic migration scripts with preview and backup — removing manual diff mistakes."_

---

# 🗓️ 14-Day Sprint (Ship Deadline)

> Không build thêm feature. Chỉ fix, expose, và document.

| #   | Item                                                            | Owner     | Status |
| :-- | :-------------------------------------------------------------- | :-------- | :----- |
| 1   | Fix 3 critical engine bugs (AFTER FIRST, FULLTEXT, FK ordering) | Engine    | [ ]    |
| 2   | CLI exit codes (0=no diff, 1=diff, 2=destructive)               | CLI       | [ ]    |
| 3   | JSON output mode (`--format json`)                              | CLI       | [ ]    |
| 4   | Destructive change warning (DROP TABLE/COLUMN)                  | CLI       | [ ]    |
| 5   | Auto backup before apply (`mysqldump` snapshot)                 | CLI       | [ ]    |
| 6   | Expose DB ↔ DB compare as CLI command                           | CLI       | [ ]    |
| 7   | README: 5-minute quickstart                                     | Docs      | [ ]    |
| 8   | Find 3 external beta users                                      | Marketing | [ ]    |

**Rule: Không làm gì ngoài 8 items này.**

---

# Phase 1: Provable Engine 🔧

> Goal: **1 developer bên ngoài** chạy `andb compare` thành công trên DB của họ.

## Diff Engine Core

- [x] Diff engine deterministic (same input → same output)
  > ✅ Proven by 32 E2E scenarios + 21 sandbox executions on Docker MySQL
- [x] Independent from table creation order
  > ✅ `reorder-columns` scenario: 0 false operations
- [x] Detect column change (type, null, default)
  > ✅ `modify-column`, `change-nullability`, `change-default` scenarios
- [x] Detect index change
  > ✅ `change-index`, `composite-index`, `prefix-length-index`, `unique-to-normal`
- [x] Detect foreign key change
  > ✅ `add-foreign-key`, `fk-drop`, `fk-multi-column` scenarios
- [ ] ~~Detect charset / collation change~~ → **DELAYED**
  > Ghi rõ limitation trong README. Không block ship.
- [ ] ~~Detect engine change~~ → **DELAYED**
  > Ghi rõ limitation trong README. Không block ship.
- [x] No false positives (INT display width, BTREE, column reorder)
  > ✅ 3 no-change scenarios verified in both E2E and sandbox

## Engine Bugs — MUST FIX BEFORE SHIP 🚨

> Dev chỉ cần 1 lần syntax error → uninstall ngay. Đây là trust killer bugs.

- [ ] `AFTER \`FIRST\``→ should generate`FIRST` (MySQL syntax)
- [ ] AFTER clause leaks into FULLTEXT KEY / INDEX statements
- [ ] FK ADD before DROP → duplicate constraint name (phải DROP trước rồi ADD)

> **Accepted limitations** (document, don't fix):
>
> - Playground only parses first table in multi-table SQL files
> - `_normalizeDef` doesn't fully resolve version-comment syntax

## CLI — Production Grade

- [x] CLI works without UI (`andb playground`, `andb compare`, `andb export`)
- [x] Fully non-interactive mode
- [ ] **Exit codes** (0=no diff, 1=diff detected, 2=destructive) ← MUST for CI
- [ ] **JSON output** (`--format json`) ← MUST for CI
- [ ] **Structured logging** (clean output, not Framework debug noise)
- [ ] ~~Config file support~~ → **DELAYED** (CLI flags đủ cho Phase 1)

> **Phản biện**: Không có exit code + JSON = không claim CI-ready. Phải có trước khi nói với user.

---

# Phase 2: Trustable Product 🛡️

> Goal: **1 team** dùng trên staging pipeline 2 tuần không incident.

## Safety Layer

- [x] Dry-run mode (engine default — preview only)
- [x] Clear script preview (CLI shows ALTER before execute)
- [ ] **Auto backup before apply** (`mysqldump` bảng bị ALTER)
  > Đây không phải technical feature. Đây là **psychological feature**.
  > _"We automatically snapshot before apply."_ → User relax 50%.
- [ ] Warning: `⚠️ Destructive change detected` khi DROP TABLE/COLUMN
- [ ] Warning: Type change may cause data loss (e.g. `varchar` → `int`)

> **Phản biện**: Cần policy engine (block DROP on prod)?
> **Trả lời**: KHÔNG. Warning đủ cho Phase 2. Policy = Phase 4+.

## Workflow

- [x] Compare: SQL file ↔ SQL file (playground)
- [ ] **Compare: DB ↔ DB** (core `compareSchema()` exists, CLI chưa expose)
  > Đây là marketing feature lớn nhất. Phải expose trước khi tìm user.
- [ ] Compare: DB ↔ SQL file
- [ ] Clean CLI output (kill Framework `[Nest] LOG` noise)
- [ ] ~~Lock mechanism~~ → **DELAYED** (concurrent migration chỉ xảy ra ở team lớn)
- [ ] ~~Version-control migration files~~ → **DELAYED**

## Documentation

- [ ] **README: 5-minute quickstart** (install → first diff in < 5 min)
- [ ] Supported MySQL versions: 8.0 confirmed, 5.7 best-effort
  > **Phản biện**: Support MariaDB?
  > **Trả lời**: KHÔNG cam kết. Nếu "happens to work" thì note, không promise.
- [ ] Known limitations section (charset, engine change, multi-table)
- [ ] Migration failure recovery guide
  > MySQL ALTER TABLE không fully transactional.
  > Phải document rõ: partial apply risk, manual revert steps.

---

# Phase 3: Revenue Ready 💰

> Goal: **1 paying customer.**

## Distribution

- [ ] Docker image published (GHCR hoặc DockerHub)
  > CI user thích `docker run` hơn `npm install -g`
- [ ] GitHub Actions example workflow
- [ ] GitLab CI example
- [ ] npm package (optional)

## Monetization

- [ ] License (dùng Keygen.sh hoặc LemonSqueezy — **KHÔNG build in-house**)
- [ ] 14-day trial
- [ ] Payment flow (Stripe/LemonSqueezy)

> **Phản biện**: Build license in-house?
> **Trả lời**: KHÔNG. Builder hay chết ở đây. 2 tuần wasted cho thứ không phải core value.

## Market Validation

- [ ] At least 1 external user (not friends/family)
- [ ] At least 1 real CI pipeline usage
- [ ] User feedback documented
- [ ] 1 case study / battle story

---

# ❌ Explicitly Delayed

| Item                                   | Reason                                       |
| :------------------------------------- | :------------------------------------------- |
| Auto rollback script generation        | Edge case vô tận. Backup + manual revert đủ. |
| Policy engine (block DROP on prod)     | Warning đủ. Policy = Phase 4+.               |
| Environment tagging (dev/staging/prod) | User tự quản lý env bằng config.             |
| Usage telemetry                        | Chưa có user thì collect gì?                 |
| Team license / seat management         | Bán 1 license cá nhân trước.                 |
| PostgreSQL driver                      | Sau khi MySQL rock solid.                    |
| Audit trail                            | Enterprise feature, Phase 5+.                |
| Config file (yaml/json)                | CLI flags đủ cho Phase 1-2.                  |

---

# 🤔 Hard Questions

- [x] Edge case coverage? → **53 scenarios, 5 bugs documented**
- [ ] "Why not Flyway?"
  > _"Andb detects schema drift automatically and generates deterministic migration scripts with preview and backup — removing manual diff mistakes."_
  > Key: không chỉ "auto gen" mà là **"prevent human diff error"**.
- [ ] Performance benchmark (300 tables, 1000 indexes, 200 FKs)
  > Nếu engine chậm ở mid-size SaaS → tool chết.
- [ ] MySQL 5.7 compatibility tested?
- [ ] Migration failure recovery documented?
  > MySQL ALTER TABLE không fully transactional. Partial apply risk phải document rõ.
- [ ] Trust model defined?
  > _"We never execute without preview. We never touch data. We only modify structure."_

---

# 📊 Current Status

```
Technical readiness:  ████████░░ 80%
Market readiness:     ███░░░░░░░ 30%
```

> Gap không phải vì thiếu feature.
> Vì: chưa có external user, chưa benchmark, chưa test 5.7, chưa có battle story.
