# 📋 The Andb - Sprint Tracker

> Living document — Planner role
> Updated: Feb 05, 2026

---

## 🎯 Current Phase: 6.5 (SSH & Distribution)

**Goal:** Complete SSH integration in Core and prepare distribution packages.

**Priority:** High

---

## 📊 Phase Status

| Phase     | Status     | Notes                                |
| --------- | ---------- | ------------------------------------ |
| Phase 0   | ✅ Done    | CoreBridge, NestJS DI, String Tokens |
| Phase 1-4 | ✅ Done    | Drivers, Comparison, Export, CLI     |
| Phase 5   | ✅ Done    | Monorepo, Electron Build, License    |
| Phase 6   | ✅ Done    | Restricted User Setup (SCA)          |
| Phase 6.5 | 🚧 Active  | SSH Tunneling in Core, Distribution  |
| Phase 7   | ⏳ Planned | PostgreSQL, Resilient Execution      |

---

## 📝 Phase 6.5 Task Breakdown

### SSH Integration (✅ Complete)

- [x] **6.5.1: SshTunnel Utility** — Create `ssh-tunnel.ts` in Core
- [x] **6.5.2: MysqlDriver Update** — Integrate SSH stream into mysql2 connection
- [x] **6.5.3: OrchestrationService** — Map UI ssh config to Core ISshConfig
- [x] **6.5.4: PrivateKey Reader** — Read key from path if privateKeyPath provided

### Distribution (🚧 In Progress)

- [ ] **6.5.5: macOS Build** — electron-builder config for v3.1.0
- [ ] **6.5.6: Code Signing** — Apple Developer certificate
- [ ] **6.5.7: Auto-Update** — Test electron-updater flow
- [ ] **6.5.8: Windows Build** — electron-builder Windows config
- [ ] **6.5.9: Linux AppImage** — Test on Ubuntu 22.04

### Polish (⏳ Pending)

- [ ] **6.5.10: SSH Form in Templates** — Add SSH fields to ConnectionTemplateManager
- [ ] **6.5.11: SSH Error Messages** — Improve error handling for SSH failures
- [ ] **6.5.12: Connection Timeout** — Configurable timeout for SSH + DB

---

## 📝 Phase 7 Preview (Enterprise)

### PostgreSQL Support

- [ ] **7.1: PostgresDriver** — Implement IDriver interface
- [ ] **7.2: Schema Introspection** — Handle `database > schema > table` hierarchy
- [ ] **7.3: Type Mapping** — JSONB, UUID, Arrays

### Resilient Execution

- [ ] **7.4: Retry Policies** — Exponential backoff for transient errors
- [ ] **7.5: Connection Pooling** — Smart pool management
- [ ] **7.6: Advisory Locks** — GET_LOCK / pg_advisory_lock

### Intelligence

- [ ] **7.7: AST Parsing** — Semantic comparison engine
- [ ] **7.8: Topological Sort** — DDL dependency graph

---

## 📅 History

- **Feb 05 (10:30)**: SSH Tunneling merged to Core. MysqlDriver now handles SSH internally.
- **Feb 03 (11:10)**: Phase 6 complete. SCA flow with premium trust-centric UI.
- **Feb 03 (10:05)**: Phase 5 complete. Monorepo unified, Proprietary license.
- **Feb 02 (10:45)**: Expanded plan with Phase 5-7 tasks.
- **Jan 29 (12:05)**: ESLint standardized, all lint errors fixed.
- **Jan 29 (11:55)**: CLI generate and helper commands ported.
