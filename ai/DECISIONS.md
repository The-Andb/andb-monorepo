# 🏛️ The Andb - Architecture Decisions

> Important decisions and their rationale

---

## Template

```markdown
## [Decision Title]

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated

### Context

_What is the issue or problem?_

### Decision

_What was decided?_

### Rationale

_Why this approach?_

### Consequences

_What are the trade-offs?_
```

---

## Decisions Log

### ADR-001: AI Folder Structure

**Date:** 2026-01-26
**Status:** Accepted

#### Context

Need organized workspace for AI-assisted development with multi-agent workflow.

#### Decision

Create `/ai` folder with:

- `CONTEXT.md` — Project context & rules
- `PLAN.md` — Living planning document
- `TODO.md` — Quick tasks
- `DECISIONS.md` — This file
- `MEMORY.md` — Long-term AI memory
- `agents/` — Agent role definitions

#### Rationale

- File-based workflow > chat-based
- Clear separation of concerns
- Easy to track & version

#### Consequences

- All AI work goes through files
- Agents have defined roles
- Memory persists across sessions

### ADR-002: Pinia Store Initialization Guards

**Date:** 2026-01-27
**Status:** Accepted

#### Context

Concurrent store initialization and project switching caused race conditions where newly created demo data was overwritten by slow loading from storage, leading to connection duplication and orphaned items.

#### Decision

All Pinia stores must implement an `initPromise` singleton guard pattern. Actions requiring a "ready" state (like `setupDemo`) must explicitly `await init()`.

#### Rationale

- Prevents intermediate "empty" state visibility.
- Ensures absolute sequential consistency during parallel reloads.
- Minimal overhead but high reliability gain.

#### Consequences

- Stores slightly more complex.
- Initialization is guaranteed to be stable and atomic.

### ADR-003: NestJS Migration for Core Architecture

**Date:** 2026-01-29
**Status:** Accepted

#### Context

`@the-andb/core` is currently a collection of loosely coupled JavaScript modules. As we move to Phase 2 (Hardening) and Phase 3 (Expansion - PostgreSQL, SSH), we face challenges with dependency management, architectural consistency, and type safety. The current manual wiring makes it difficult to add new drivers (Postgres) without significant refactoring or messy abstractions.

#### Decision

Refactor `@the-andb/core` to use **NestJS**.
Adopt a **"Twin Engine"** strategy:

1.  **Isolation**: Build the new engine in a separate folder (`core-nest`) alongside the existing `core`.
2.  **Compatibility**: Retain the existing `core` until the new engine passes all "Mirror Tests" (identical output verification).
3.  **Strict Mode**: Use TypeScript with strict type checking.

#### Rationale

- **Dependency Injection**: Solves the multi-driver problem by allowing us to inject `MysqlDriver` or `PostgresDriver` dynamically.
- **Enterprise Structure**: Modules, Services, and Controllers provide a proven scalable architecture.
- **CLI Support**: `nestjs-commander` simplifies CLI development.
- **Future Proofing**: Prepared for "Server Mode" (Team Collaboration) if needed later.

#### Consequences

- **Learning Curve**: Requires adhering to NestJS patterns (Modules, Providers).
- **Setup Effort**: Initial boilerplate and wiring overhead is higher than vanilla JS.
- **Improved Maintainability**: Long-term maintenance becomes significantly easier with strict boundaries and typing.

### ADR-004: MySQL-Only Implementation (Phase 2)

**Date:** 2026-01-29
**Status:** Accepted

#### Context

While the NestJS architecture supports multi-driver dependency injection (PostgreSQL, SQLite), the immediate goal is to stabilize and harden the existing MySQL functionality before expanding. Introducing PostgreSQL implementation details now would dilute focus and increase complexity without delivering immediate value.

#### Decision

**Design for abstraction, implement only MySQL.**

- The `IDatabaseDriver` interface remains generic and decoupled.
- We will ONLY implement `MysqlDriver` and `MysqlIntrospectionService` in this phase.
- No PostgreSQL code or dependencies will be added yet.
- Strict decoupling must be maintained so that adding Postgres later is purely additive (adding a new module/provider) without touching the Core logic.

#### Rationale

- **"Deep before Wide"**: Master MySQL nuances (procedures, triggers, events) fully before switching contexts.
- **Safety**: Reduces the surface area for bugs during the refactor.
- **Clean Architecture**: Enforces the discipline of "coding to an interface" without the temptation of premature optimization for a second driver.

#### Consequences

- The system is architecturally ready for Postgres, but functionally MySQL-only.
- Future Postgres expansion becomes a focused "Fill in the blank" exercise.

### ADR-005: Strategy Pattern for Offline Dump Comparison

**Date:** 2026-01-29
**Status:** Accepted

#### Context
"Offline Comparison" (Dump File vs DB or Dump vs Dump) is a critical feature. User needs to compare standard SQL dump files (`.sql`) without importing them into a database server first.
The current `IDatabaseDriver` interface assumes a connection to a live server.

#### Decision
Implement `DumpDriver` adhering to `IDatabaseDriver`.
- It acts as a "Virtual Driver" that "connects" by parsing a local file.
- It provides an `IntrospectionService` powered by parsed memory objects.
- It is injectable via `DriverModule` using the same Factory logic (based on config `type: 'dump'`).

#### Rationale
- **Uniformity:** The `ComparatorService` and UI don't need to know if they are talking to a live DB or a file. They just call `driver.getIntrospectionService().listTables()`.
- **Flexibility:** Enables powerful flows like "Prod DB vs Local Dump" or "Dump v1 vs Dump v2" using the exact same diffing engine.

#### Consequences
- Must implement a robust SQL Parser in `DumpDriver` to accurately mimic `SHOW CREATE TABLE`.
- Limited functionality: `query()` method is stubbed/not supported.
