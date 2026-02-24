# 🎯 The Andb Executive Roadmap (2026)

**Mission:** Transform `The Andb` from a personal tool into a commercial-grade database management product.

**Current Status:** Phase 6.5 (Polish & Pro Features) — SSH Integration Complete

---

## 📊 Strategic Timeline

| Phase         | Focus Area             | Key Deliverables                             | Timeline     | Status         |
| :------------ | :--------------------- | :------------------------------------------- | :----------- | :------------- |
| **Phase 0**   | **Decoupling**         | CoreBridge, NestJS DI, String Tokens         | Jan 2026     | ✅ Complete    |
| **Phase 1-4** | **Foundation**         | MySQL Driver, Comparison Engine, CLI         | Jan 2026     | ✅ Complete    |
| **Phase 5**   | **Monorepo**           | Electron Build, License, Legacy Archive      | Feb 2026     | ✅ Complete    |
| **Phase 6**   | **Secure Connections** | Restricted User Setup (SCA), Trust UI        | Feb 2026     | ✅ Complete    |
| **Phase 6.5** | **SSH & Polish**       | Native SSH Tunneling, Distribution Prep      | Feb 2026     | 🚧 In Progress |
| **Phase 7**   | **Enterprise**         | PostgreSQL, Resilient Execution, AST Parsing | Feb-Mar 2026 | ⏳ Planned     |
| **Phase 8**   | **Commercialization**  | Pro License, Team Tools, Cloud Auth          | Mar 2026+    | ⏳ Planned     |

---

## 📦 Package Structure

| Package          | Role                           | Tech Stack                 |
| ---------------- | ------------------------------ | -------------------------- |
| `@the-andb/core` | Pure business logic, stateless | NestJS, TypeScript, mysql2 |
| `@the-andb/ui`   | Electron + Vue 3 desktop       | Vue 3, Pinia, Tailwind     |
| `@the-andb/cli`  | Terminal interface             | nest-commander             |
| `andb-www`       | Landing page & docs            | Astro/Static               |

**Core Principle:** All logic in `core`. UI/CLI are adapters only.

---

## 🏆 Phase 6.5 Deliverables (Current)

### ✅ Completed

- **SSH Tunneling**: Native `ssh2` integration in Core (`ssh-tunnel.ts`)
- **MysqlDriver**: Auto-detect `sshConfig` and establish tunnel before connect
- **OrchestrationService**: Map UI ssh object → Core ISshConfig

### 🎯 Remaining

- **Distribution**: macOS v3.1.0 build with code signing
- **Connection Templates**: SSH fields in global template manager
- **Error Handling**: SSH-specific error messages

---

## 🗺️ Phase 7: Enterprise Features (Feb-Mar 2026)

| Feature                 | Priority | Description                                          |
| ----------------------- | -------- | ---------------------------------------------------- |
| **PostgreSQL Driver**   | High     | Implement `IDriver` for Postgres with schema support |
| **Resilient Execution** | High     | Retry policies, Connection pooling                   |
| **AST Parsing**         | Medium   | Semantic comparison (ignore whitespace, aliases)     |
| **Topological Sort**    | Medium   | DDL dependency graph for safe migration order        |
| **Pre-flight Checks**   | Medium   | Replication lag, active queries, disk space          |

---

## 💰 Phase 8: Commercial Strategy (Mar 2026+)

### Open Core Model

- **Community Edition (Free):** Core engine, MySQL/PostgreSQL, CLI, Basic UI
- **Pro Edition (Paid):** SSH Tunneling\*, Safe Mode, Team Collaboration, Priority Support

\*Note: SSH is currently in Community but may move to Pro tier

### Pro Features Pipeline

| Feature           | Description                             |
| ----------------- | --------------------------------------- |
| Transaction Guard | Auto-commit OFF, explicit confirmation  |
| Team Sync         | Shared projects, audit logs             |
| Cloud Auth        | AWS RDS IAM, GCP Cloud SQL integration  |
| Data Masking      | Sanitize prod data for dev environments |

---

## 📊 Feature Parity Status

| Area             | Legacy           | Next-Gen            | Status     |
| ---------------- | ---------------- | ------------------- | ---------- |
| Architecture     | Monolithic JS    | Modular NestJS (DI) | ✅ Done    |
| MySQL Driver     | mysql2           | mysql2 + SSH        | ✅ Done    |
| Dump Driver      | N/A              | FileStorage-based   | ✅ Done    |
| SSH Tunneling    | Separate utility | Driver-integrated   | ✅ Done    |
| Tables Compare   | Text Diff        | Semantic Diff       | ✅ Done    |
| Views/Routines   | Text Diff        | Normalized Diff     | ✅ Done    |
| Migration        | String Concat    | MigratorService     | ✅ Done    |
| PostgreSQL       | Experimental     | Dedicated Driver    | ⏳ Planned |
| Transaction Safe | N/A              | Virtual Dry Run     | ⏳ Planned |

---

## 📅 History

| Date   | Event                                                                   |
| ------ | ----------------------------------------------------------------------- |
| Feb 23 | Decoupled CLI from Core, built `andb playground` for local diff testing |
| Feb 05 | SSH Tunneling migrated to Core (ssh-tunnel.ts, MysqlDriver)             |
| Feb 03 | Restricted User Setup (SCA) flow completed                              |
| Feb 02 | Monorepo unified, License updated to Proprietary                        |
| Jan 29 | CoreBridge pattern, NestJS DI stabilized                                |
| Jan 27 | CLI ported to nest-commander                                            |

---

_Verified by Engineering Team: Feb 2026_
