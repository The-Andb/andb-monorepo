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

### ADR-003: Framework Migration for Core Architecture

**Date:** 2026-01-29
**Status:** Accepted

#### Context

`@the-andb/core` is currently a collection of loosely coupled JavaScript modules. As we move to Phase 2 (Hardening) and Phase 3 (Expansion - PostgreSQL, SSH), we face challenges with dependency management, architectural consistency, and type safety. The current manual wiring makes it difficult to add new drivers (Postgres) without significant refactoring or messy abstractions.

#### Decision

Refactor `@the-andb/core` to use **Framework**.
Adopt a **"Twin Engine"** strategy:

1.  **Isolation**: Build the new engine in a separate folder (`core-nest`) alongside the existing `core`.
2.  **Compatibility**: Retain the existing `core` until the new engine passes all "Mirror Tests" (identical output verification).
3.  **Strict Mode**: Use TypeScript with strict type checking.

#### Rationale

- **Dependency Injection**: Solves the multi-driver problem by allowing us to inject `MysqlDriver` or `PostgresDriver` dynamically.
- **Enterprise Structure**: Modules, Services, and Controllers provide a proven scalable architecture.
- **CLI Support**: `Framework-commander` simplifies CLI development.
- **Future Proofing**: Prepared for "Server Mode" (Team Collaboration) if needed later.

#### Consequences

- **Learning Curve**: Requires adhering to Framework patterns (Modules, Providers).
- **Setup Effort**: Initial boilerplate and wiring overhead is higher than vanilla JS.
- **Improved Maintainability**: Long-term maintenance becomes significantly easier with strict boundaries and typing.

### ADR-004: MySQL-Only Implementation (Phase 2)

**Date:** 2026-01-29
**Status:** Accepted

#### Context

While the Framework architecture supports multi-driver dependency injection (PostgreSQL, SQLite), the immediate goal is to stabilize and harden the existing MySQL functionality before expanding. Introducing PostgreSQL implementation details now would dilute focus and increase complexity without delivering immediate value.

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

### ADR-006: Centralized SQL Generation in Core

**Date:** 2026-02-04
**Status:** Accepted

#### Context

User setup requires SQL scripts that are database-specific (MySQL, Postgres, etc.). Generating these in the UI (Vue components) violates the architectural rule of keeping business/database logic in `core`. It also makes maintenance difficult and error-prone across different adapters (UI, CLI).

#### Decision

Implement `generateUserSetupScript` in the `IDatabaseDriver` interface.

- Each driver (e.g., `MysqlDriver`) implements its own script generation logic.
- `OrchestrationService` exposes this through a unified API.
- UI/CLI adapters only request the script and display/execute it.

#### Rationale

- **Single Source of Truth**: Database-specific logic belongs to the driver.
- **Safety**: Inputs can be sanitized centrally.
- **Consistency**: UI and CLI will always generate identical setup scripts.

#### Consequences

- Drivers are slightly more complex.

### ADR-007: Inherit & Protect Connection Model

**Date:** 2026-02-04
**Status:** Accepted

#### Context

The application currently has redundant connection forms at both the Global (Settings) and Project levels. This leading to "duplicate form" fatigue and inconsistent security configurations. Additionally, SSH tunneling is required but difficult to manage if distributed across every project connection.

#### Decision

Implement an **"Inherit & Protect"** architectural model for database connections:

1.  **Central Source of Truth**: All infrastructure details (Host, Port, Username, Password, SSH Tunneling) are defined ONLY at the Global level (Connection Templates).
2.  **Enforced Inheritance**: Project-level connections MUST inherit from a Global Template and cannot override core host/credential settings.
3.  **Project-Specific Context**: Projects are only allowed to define/override the `database` name (if applicable) and `environment` (e.g., UAT vs Prod) to keep maintenance focused.
4.  **Global SSH**: SSH tunnels are configured once per template, ensuring all project instances sharing that infrastructure benefit from the same secure tunnel.

#### Rationale

- **Security Compliance**: Sensitive info is centralized, making it easier to rotate credentials.
- **Maintenance**: Changing a server's IP in one Global Template updates all associated Project connections instantly.
- **Architectural Clarity**: Clearly separates "Infrastructure" (Global) from "Application Context" (Project).

#### Consequences

- UI at Project level will be simplified (Select Template > Verify Masked Info).
- Existing direct project connections must be migrated to the template-based model.
- Requires robust Global Template management UI.

### ADR-008: Strict Separation of CLI and Core Logic

**Date:** 2026-02-23
**Status:** Accepted

#### Context

`@the-andb/core` was acting as both the business logic library and the terminal interface by bundling `nest-commander` and CLI commands directly within its `AppModule` and `src/cli` directory. This violated the architecture principle where Core should be pure logic and CLI acts simply as an adapter. It also added unnecessary terminal dependencies and weight when Core was imported by `andb-ui`. At the same time, we needed to build `andb playground` to rapidly test semantic comparison of schemas locally.

#### Decision

Completely decouple CLI logic from `@the-andb/core` and move it to `@the-andb/cli`.

- `@the-andb/core` becomes a pure library, exporting internal feature modules (`ParserModule`, `OrchestrationModule`, etc.).
- `@the-andb/cli` handles its own Framework context via `CliModule`, instantiates terminal commands, reads local `.sql` files, and delegates logic to the Core modules.

#### Rationale

- **YAGNI/DRY Architecture**: Keeps `core` strictly decoupled from terminal presentation logic.
- **Weight**: UI application does not inadvertently load CLI packages (`commander`, `nest-commander`).
- **Simplicity**: Provides a dedicated package for building advanced CI/CD scripts and the `playground` tool.

#### Consequences

### ADR-009: Sidebar Depth Optimization (Category-Level Navigation)

**Date:** 2026-03-04
**Status:** Accepted

#### Context

The Sidebar's Schema Explorer tree was rendering individual database objects (Tables, Views, Procedures, Functions, Triggers, Events) as the final leaf nodes. In large schemas with hundreds or thousands of objects, this caused massive DOM bloat, high memory consumption, and significant scroll-lag. Furthermore, the UI already supports "Miller Columns" or main-view browsing, making the sidebar representation redundant for deep exploration.

#### Decision

Limit the Schema Explorer tree depth to **DDL Category level** (e.g., "Tables", "Views").

- Individual objects (leaf nodes) will NO LONGER be rendered in the sidebar.
- Clicking on a Category will now correctly trigger navigation or filtering in the main view (GlobalSchemaView).
- Associated logic for individual object selection (`selectObject`, `selectedObjectId`, `refreshObject`) is removed from the Sidebar to reduce bundle size and complexity.

#### Rationale

- **Performance**: Instant render times even for very large databases.
- **UX**: Cleaner, more focused navigation that aligns with the "Deep Browse in Main View" pattern.
- **Maintainability**: Reduced template complexity and fewer reactive state dependencies.

#### Consequences

- Main view must handle object list display and filtering comprehensively as it is now the primary path for individual object selection.
- Search within the Sidebar must still be effective, likely by highlighting matching categories.
- User will use the main view (Miller column or List) to perform specific object actions (e.g., refresh single table, view DDL).

---

### ADR-010: Strategic Repositioning — DB Guard (Production Safety System)

**Date:** 2026-03-04
**Status:** Accepted

#### Context

The Andb started as a "DB Compare Tool" — a utility for diffing and migrating MySQL schemas. While technically sound, this positioning limits market appeal and monetization potential. The core engine is already capable of detecting schema drift, classifying risk, and generating deterministic migration scripts.

#### Decision

Reposition the product from **"DB Compare Tool"** to **"Production Safety System" (DB Guard)**. The 6-month execution plan is documented in [guard.plan.md](file:///Volumes/FlexibleWorkplace/The-Andb/plans/guard.plan.md).

Key pillars:

1. **Risk Prevention** — Block risky deployments via CI integration.
2. **Drift Detection** — Continuous monitoring of schema divergence across environments.
3. **Audit Timeline** — Historical schema change tracking for compliance.

#### Rationale

- "Sell risk reduction, not features" — teams pay for preventing outages, not for diffing.
- The `SafetyReport` engine (SAFE/WARNING/CRITICAL) already provides the foundation.
- CI/CD integration (GitHub Actions) is the primary distribution channel for DevOps teams.

#### Consequences

- Phase 3 of the roadmap now includes Drift Detection Agent and Deployment Guard.
- ICP shifts from solo developers to teams (5–30 engineers) with multiple environments.
- Pricing model will follow Free → Team ($29–79/mo) → Growth ($149+/mo) tiers.
### ADR-011: Stable Release v4.0.0 (The Andb)

**Date:** 2026-03-11
**Status:** Accepted

#### Context

The project has reached a level of stability across the Core engine, CLI, and Desktop application that warrants a transition from Beta to the first major Stable release. We have achieved 100% unit test pass rates and successfully implemented long-requested features like Search Content and Go to Definition.

#### Decision

Launch **The Andb v4.0.0** (Stable).

- Bump versions: Core/CLI/MCP to `4.0.0`, Desktop to `3.1.0`, WWW to `1.1.0`.
- Finalize the rebranding from "Andb" to "**The Andb**" with the tagline "**Simplest Database Migration Tool**".
- Standardize internal dependencies to explicit stable versions instead of `workspace:*` for final artifacts.

#### Rationale

- **Market Readiness**: The product is now ready for production use by teams and professional developers.
- **Brand Consistency**: Solidifies the brand identity before aggressive growth in Phase 3.
- **Quality Assurance**: 100% test coverage and successful real-world schema migrations provide the necessary confidence.

#### Consequences

- Need for formal release notes and production distribution channels.
- Transition from "building features" to "maintaining stability & incremental growth".
- Shift in documentation tone to authoritative and professional.
