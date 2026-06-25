# The-Andb — Pointer

Agent config moved to **Anph2ndBrain**. Read before coding:

- `/Volumes/FlexibleWorkplace/Anph2ndBrain/CLAUDE.md` (master)
- `/Volumes/FlexibleWorkplace/Anph2ndBrain/projects/side/anph/theandb/context.mdc`
- `/Volumes/FlexibleWorkplace/Anph2ndBrain/projects/side/anph/theandb/CLAUDE.md` (full doc + GitNexus)

Init: skill `init-project-brain` · marker: `.brain-root`

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **andb-monorepo** (1216 symbols, 1188 relationships, 0 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/andb-monorepo/context` | Codebase overview, check index freshness |
| `gitnexus://repo/andb-monorepo/clusters` | All functional areas |
| `gitnexus://repo/andb-monorepo/processes` | All execution flows |
| `gitnexus://repo/andb-monorepo/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `/Volumes/FlexibleWorkplace/Anph2ndBrain/projects/side/anph/theandb/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `/Volumes/FlexibleWorkplace/Anph2ndBrain/projects/side/anph/theandb/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `/Volumes/FlexibleWorkplace/Anph2ndBrain/projects/side/anph/theandb/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `/Volumes/FlexibleWorkplace/Anph2ndBrain/projects/side/anph/theandb/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `/Volumes/FlexibleWorkplace/Anph2ndBrain/projects/side/anph/theandb/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `/Volumes/FlexibleWorkplace/Anph2ndBrain/projects/side/anph/theandb/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
