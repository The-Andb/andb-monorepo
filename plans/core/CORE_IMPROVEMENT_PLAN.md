# Core Improvement Roadmap

> Updated: Feb 24, 2026
> Scope trimmed to realistic priorities. Enterprise features explicitly delayed.

---

## ✅ Phase 0: Foundation — DONE

- [x] CoreBridge pattern (UI/CLI decoupled from service internals)
- [x] Framework DI with string tokens
- [x] Abstract `IDatabaseDriver` interface
- [x] MySQL driver with SSH tunneling

## ✅ Phase 1: Semantic Comparison — DONE

- [x] Structured table parsing (columns, indexes, FKs)
- [x] Normalization engine (`_normalizeDef`: INT display width, BTREE, version comments)
- [x] ALTER TABLE generation with proper clause ordering
- [x] View/Procedure/Trigger normalized text comparison

## 🚧 Phase 2: Ship Quality — IN PROGRESS (14-day sprint)

- [x] Fix AFTER FIRST syntax bug
- [x] Fix AFTER leak into index definitions
- [x] Fix FK ADD before DROP ordering
- [x] Exit codes (0/1/2)
- [x] JSON / YAML output mode
- [x] Destructive change warnings
- [x] Clean structured logging (remove Framework noise)
- [ ] Auto backup (`mysqldump`) before apply
- [ ] DB ↔ DB comparison CLI (Standardized)
- [ ] README quickstart & Beta user finding

## ⏳ Phase 3: Scale & Reliability — NEXT

- [ ] Performance testing (300+ tables)
- [ ] MySQL 5.7 compatibility
- [ ] Resilient execution (retry, connection pooling)
- [ ] DB ↔ SQL file comparison
- [ ] Charset / collation / engine change detection

---

## ❌ Explicitly Delayed

| Feature                             | Reason                                            |
| :---------------------------------- | :------------------------------------------------ |
| AST-based SQL parsing               | Current regex/semantic parser covers 95% of cases |
| PostgreSQL driver                   | After MySQL rock solid                            |
| Topological sort (dependency graph) | Nice-to-have, not blocking ship                   |
| Online Schema Change (gh-ost)       | Enterprise feature                                |
| Data masking / seeding              | Out of scope for CLI diff tool                    |
| Advisory locks                      | Only needed by large teams                        |
| Transactional dry run               | MySQL DDL implicit commits make this impractical  |
