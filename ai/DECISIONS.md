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
