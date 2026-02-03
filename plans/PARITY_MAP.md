# 🗺️ Feature Parity Map

This document tracks the feature parity between the **Next-Gen System** (NestJS/Vue3) and the **Legacy System** (Node.js/Vue2).
Our goal is 100% parity before the full legacy sunset.

## 🧠 Core Engine Parity

| Feature Area     | Legacy (`andb-core-legacy`)  | Next-Gen (`andb-core`) | Status         | Notes                           |
| :--------------- | :--------------------------- | :--------------------- | :------------- | :------------------------------ |
| **Architecture** | Monolithic / Node.js Scripts | Modular / NestJS       | ✅ Done        | Better DI, Testability          |
| **Parsing**      | Regex-based (`sql-parser`)   | AST/Regex Hybrid       | ✅ Done        | More accurate                   |
| **Drivers**      | MySQL                        | MySQL, DumpDriver      | ✅ Done        | DumpDriver added                |
| **Comparison**   |
| - Tables         | Basic Diff                   | Semantic Diff          | ✅ Done        | Type consolidation              |
| - Views          | Text Diff                    | Normalized Text Diff   | ✅ Done        | Ignores whitespace              |
| - Routines       | Text Diff                    | Normalized Text Diff   | ✅ Done        | (Procedures/Functions)          |
| - Triggers       | Text Diff                    | Normalized Text Diff   | ✅ Done        |                                 |
| - Events         | Text Diff                    | Normalized Text Diff   | ✅ Done        |                                 |
| **Migration**    |
| - Generation     | String Concatenation         | `MigratorService`      | ✅ Done        | Safe ALTER generation           |
| - Safety         | N/A                          | `Session/Transaction`  | ⚠️ In Progress | Need detailed transaction logs  |
| **CLI**          | `commander`                  | `nest-commander`       | ✅ Done        | `generate`, `export`, `compare` |
| **Reporting**    | EJS Templates                | `ReportService`        | ✅ Done        | High fidelity HTML reports      |

---

## 🎨 UI / Desktop Parity

| Feature Area   | Legacy (`andb-desktop-legacy`) | Next-Gen (`andb-desktop`) | Status     | Notes                             |
| :------------- | :----------------------------- | :------------------------ | :--------- | :-------------------------------- |
| **Tech Stack** | Vue 2 / Options API            | Vue 3 / Composition API   | ✅ Done    | Faster, Type-safe                 |
| **Connection** |
| - Manager      | Basic List                     | Sidebar + Search          | ✅ Done    | Auto-hide sidebar                 |
| - SSH Tunnel   | `ssh2`                         | Native/`ssh2`             | ✅ Done    | improved stability                |
| - Groups       | N/A                            | Environment Groups        | ✅ Done    | Dev/Stage/Prod grouping           |
| **Workspace**  |
| - Context      | Single Global                  | Project Context           | ✅ Done    | Isolate configs per project       |
| - Tab System   | Basic Tabs                     | Multi-tab / Split Pane    | ✅ Done    | Resizable panes                   |
| **Comparison** |
| - View         | Raw Text Diff                  | Monaco Diff Editor        | ✅ Done    | Syntax Highlighting               |
| - Object List  | Flat List                      | Tree View                 | ✅ Done    | Better hierarchy                  |
| - Actions      | Sync All                       | Atomic Sync               | ✅ Done    | Sync individual objects           |
| **Query**      |
| - Editor       | Simple Textarea                | Monaco Editor             | ✅ Done    | Auto-complete support             |
| - Results      | HTML Table                     | Virtualized Table         | ⚠️ Partial | Need better large result handling |
| **Settings**   | JSON File                      | Settings UI               | ✅ Done    | Theme switching                   |

---

## 🚦 Roadmap needed for Full Parity

1.  **PostgreSQL Support**: Legacy had experimental support. Next-Gen needs a proper `PostgresDriver`.
2.  **Complex Data Migration**: Legacy had some data sync tools. Next-Gen focuses on Schema first.
3.  **Plugin System**: Next-Gen architecture allows plugins, but none implemented yet.
