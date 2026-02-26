# 🗺️ Feature Parity Map

> Tracking feature parity between Legacy and Next-Gen systems.
> Updated: Feb 05, 2026

---

## 🧠 Core Engine Parity

| Feature Area     | Legacy (`andb-core-legacy`)  | Next-Gen (`andb-core`) | Status     | Notes                       |
| :--------------- | :--------------------------- | :--------------------- | :--------- | :-------------------------- |
| **Architecture** | Monolithic / Node.js Scripts | Modular / NestJS       | ✅ Done    | Better DI, Testability      |
| **Parsing**      | Regex-based (`sql-parser`)   | AST/Regex Hybrid       | ✅ Done    | More accurate               |
| **Drivers**      |                              |                        |            |                             |
| - MySQL          | Native mysql2                | mysql2 + SSH Tunnel    | ✅ Done    | SSH integrated in driver    |
| - Dump           | N/A                          | FileStorage-based      | ✅ Done    | For offline comparison      |
| - PostgreSQL     | Experimental                 | Dedicated Driver       | ⏳ Planned | Phase 7                     |
| **SSH Tunnel**   | Separate utility             | Driver-integrated      | ✅ Done    | Core handles SSH internally |
| **Comparison**   |                              |                        |            |                             |
| - Tables         | Basic Diff                   | Semantic Diff          | ✅ Done    | Type consolidation          |
| - Views          | Text Diff                    | Normalized Text Diff   | ✅ Done    | Ignores whitespace          |
| - Routines       | Text Diff                    | Normalized Text Diff   | ✅ Done    | Procedures/Functions        |
| - Triggers       | Text Diff                    | Normalized Text Diff   | ✅ Done    |                             |
| - Events         | Text Diff                    | Normalized Text Diff   | ✅ Done    |                             |
| **Migration**    |                              |                        |            |                             |
| - Generation     | String Concatenation         | `MigratorService`      | ✅ Done    | Safe ALTER generation       |
| - Safety         | N/A                          | Virtual Dry Run        | ⏳ Planned | Shadow table approach       |
| **CLI**          | `commander`                  | `nest-commander`       | ✅ Done    | export, compare, migrate    |
| **Reporting**    | EJS Templates                | `ReportService`        | ✅ Done    | High fidelity HTML reports  |

---

## 🎨 UI / Desktop Parity

| Feature Area     | Legacy (`andb-desktop-legacy`) | Next-Gen (`andb-desktop`)  | Status     | Notes                       |
| :--------------- | :----------------------------- | :------------------------- | :--------- | :-------------------------- |
| **Tech Stack**   | Vue 2 / Options API            | Vue 3 / Composition API    | ✅ Done    | Faster, Type-safe           |
| **Connection**   |                                |                            |            |                             |
| - Manager        | Basic List                     | Sidebar + Search           | ✅ Done    | Auto-hide sidebar           |
| - SSH Tunnel     | UI-handled                     | Core-handled               | ✅ Done    | Config only in UI           |
| - Templates      | N/A                            | Global Templates + SSH     | ✅ Done    | Inherit & Protect pattern   |
| - Groups         | N/A                            | Environment Groups         | ✅ Done    | Dev/Stage/Prod grouping     |
| **Secure Setup** | N/A                            | Restricted User Flow (SCA) | ✅ Done    | Auto/Manual modes           |
| **Workspace**    |                                |                            |            |                             |
| - Context        | Single Global                  | Project Context            | ✅ Done    | Isolate configs per project |
| - Tab System     | Basic Tabs                     | Multi-tab / Split Pane     | ✅ Done    | Resizable panes             |
| **Comparison**   |                                |                            |            |                             |
| - View           | Raw Text Diff                  | Monaco Diff Editor         | ✅ Done    | Syntax Highlighting         |
| - Object List    | Flat List                      | Tree View                  | ✅ Done    | Better hierarchy            |
| - Actions        | Sync All                       | Atomic Sync                | ✅ Done    | Sync individual objects     |
| **Query**        |                                |                            |            |                             |
| - Editor         | Simple Textarea                | Monaco Editor              | ✅ Done    | Auto-complete support       |
| - Results        | HTML Table                     | Virtualized Table          | ⚠️ Partial | Large result handling WIP   |
| **Settings**     | JSON File                      | Settings UI                | ✅ Done    | Theme switching             |

---

## 🚦 Remaining for Full Parity

1. **PostgreSQL Support**: Legacy had experimental support. Next-Gen needs proper `PostgresDriver`.
2. **Virtual Dry Run**: Transaction safety for DDL migrations.
3. **Large Result Handling**: Virtualized table for 100k+ rows.
