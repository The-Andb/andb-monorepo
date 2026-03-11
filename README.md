# The Andb 🛸

**Professional Database Schema Reliability Engine.**  
AST-powered Safety, Semantic Diffing, and Multi-Environment Orchestration for High-Stakes Production.

---

[![Fast: 5-Min Setup](https://img.shields.io/badge/Setup-5--Minute-blueviolet?style=for-the-badge&logo=rocket)](#-quickstart)
[![Safety: AST-Analyzed](https://img.shields.io/badge/Safety-AST--Analyzed-green?style=for-the-badge&logo=shield)](https://github.com/ph4n4n/the-andb-core)
[![License: Source-Available](https://img.shields.io/badge/License-Source--Available-orange?style=for-the-badge)](./LICENSE)

The Andb is a developer-first tool built to eliminate the common pain points of database migrations: accidental data loss, schema drift, and complex manual SQL generation. It understands your database structure not just as text, but as a semantic model.

## ✨ Key Differentiators

- **Live-State Diffing**: No need for complex migration histories. Diff your live `dev` directly against `prod`.
- **Safety-First Engine**: Every migration is AST-analyzed for destructive operations (dropping columns, narrowing types) with automated warnings.
- **Rich Aesthetics**: Human-readable diffs and reports that actually make sense to engineers.
- **AI-Ready**: Bundled with an **MCP Server** to let Claude/ChatGPT perform safe schema audits for you.

---

## ⚡ Quickstart (5 Minutes)

The fastest way to experience The Andb is comparing the bundled test databases.

### 1. Build & Link

```bash
# Register the core engine
cd andb-core && npm install && npm run build && npm link && cd ..

# Install the CLI
cd andb-cli && npm install && npm link @the-andb/core && npm link && cd ..
```

### 2. Spin up Test DBs

```bash
docker-compose -f docker/docker-compose.yml up -d
```

_Starts `mysql-dev` (3307) and `mysql-prod` (3310)._

### 3. Run Your First Diff!

Create a simple `andb.yaml` file (see [example](file:///Volumes/FlexibleWorkplace/The-Andb/andb-cli/andb.yaml)) and run:

```bash
andb compare dev prod
```

> [!TIP]
> **Clean Pipe Execution**: The CLI redirects logging to `stderr`, keeping `stdout` pure. You can pipe the migration SQL safely: `andb compare dev prod > migration.sql`.

---

## 📂 Repository Tour

| Module                                                                        | Role                                                                        |
| :---------------------------------------------------------------------------- | :-------------------------------------------------------------------------- |
| **[`andb-core`](file:///Volumes/FlexibleWorkplace/The-Andb/andb-core)**       | The "Brain". Handles AST parsing, diffing logic, and SQL generation.        |
| **[`andb-cli`](file:///Volumes/FlexibleWorkplace/The-Andb/andb-cli)**         | The primary interface for developers and CI/CD pipelines.                   |
| **[`andb-desktop`](file:///Volumes/FlexibleWorkplace/The-Andb/andb-desktop)** | Premium GUI for visual schema management and drift audits (Electron + Vue). |
| **[`andb-mcp`](file:///Volumes/FlexibleWorkplace/The-Andb/andb-mcp)**         | Model Context Protocol server for AI agent integration.                     |

---

## ⚖️ License

**The Andb Public License (APL-1.0)**  
Free for evaluation, education, and local testing. Commercial use requires a license.  
See [LICENSE](./LICENSE) and [COMMERCIAL.md](./COMMERCIAL.md).

---

Built with ❤️ by **The Andb Team**. Contact: `ph4n4n@gmail.com`
