# TheAndb 🛸

**Professional Database Schema Reliability Engine.**
AST-powered Safety, Semantic Diffing, and Multi-Environment Orchestration for High-Stakes Production.

---

[![Fast: 5-Min Setup](https://img.shields.io/badge/Setup-5--Minute-blueviolet?style=for-the-badge&logo=rocket)](#-quickstart)
[![Safety: AST-Analyzed](https://img.shields.io/badge/Safety-AST--Analyzed-green?style=for-the-badge&logo=shield)](https://github.com/The-Andb/andb-core)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue?style=for-the-badge&logo=gnu)](./LICENSE)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ff69b4?style=for-the-badge&logo=githubsponsors)](https://github.com/sponsors/The-Andb)

TheAndb is a developer-first tool built to eliminate the common pain points of database migrations: accidental data loss, schema drift, and complex manual SQL generation. It understands your database structure not just as text, but as a semantic model.

## ✨ Key Differentiators

- **Live-State Diffing**: No need for complex migration histories. Diff your live `dev` directly against `prod`.
- **Safety-First Engine**: Every migration is AST-analyzed for destructive operations (dropping columns, narrowing types) with automated warnings.
- **Rich Aesthetics**: Human-readable diffs and reports that actually make sense to engineers.
- **AI-Ready**: Bundled with an **MCP Server** to let Claude/ChatGPT perform safe schema audits for you.

---

## ⚡ Quickstart (5 Minutes)

The fastest way to experience TheAndb is comparing the bundled test databases.

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

## 🛠️ How to Checkout

This repository acts as a specialized orchestrator for TheAndb ecosystem. To get the full source for all components (Cross-platform support for macOS/Windows/Linux):

```bash
# 1. Install pnpm (if not already present)
npm install -g pnpm

# 2. Clone this main repo
git clone https://github.com/The-Andb/andb-monorepo.git

# 3. Hydrate all sub-repositories (Core, CLI, Desktop, MCP, etc.)
npm run repo:clone

# 4. Pull updates for all sub-repos simultaneously
npm run repo:pull

# 5. Install all dependencies (Workspace-aware)
npm run repo:install
```

---

## 📂 Repository Tour

| Module                                                                        | Role                                                                        |
| :---------------------------------------------------------------------------- | :-------------------------------------------------------------------------- |
| **[`andb-core`](file:///Volumes/FlexibleWorkplace/The-Andb/andb-core)**       | The "Brain". Handles AST parsing, diffing logic, and SQL generation.        |
| **[`andb-cli`](file:///Volumes/FlexibleWorkplace/The-Andb/andb-cli)**         | The primary interface for developers and CI/CD pipelines.                   |
| **[`andb-desktop`](file:///Volumes/FlexibleWorkplace/The-Andb/andb-desktop)** | Visual schema management and drift-audit GUI (Electron + Vue).             |
| **[`andb-mcp`](file:///Volumes/FlexibleWorkplace/The-Andb/andb-mcp)**         | Model Context Protocol server for AI agent integration.                     |

---

## ⚖️ License

TheAndb is **fully open source under AGPL-3.0** — engine, CLI, MCP server, desktop app, and website all ship under the same license. There's no closed-source tier. A commercial license is only needed if you re-host TheAndb as a competing managed SaaS or white-label it without publishing your changes — see [COMMERCIAL.md](./COMMERCIAL.md) for specifics.

See [LICENSE](./LICENSE) for the full AGPL-3.0 text.

## ❤️ Sponsor

> Software is like sex: it's better when it's free. No hidden repositories, no source-available tricks — just real open source. Sponsorship doesn't unlock code; it keeps the servers running and buys more time to build.

See [SPONSORS.md](./SPONSORS.md) for tiers and funding goals, or **[sponsor on GitHub →](https://github.com/sponsors/The-Andb)**

---

Built with ❤️ by **TheAndb Team**. Contact: `ph4n4n@gmail.com`
