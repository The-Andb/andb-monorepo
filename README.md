# The Andb Main Hierarchy

Monorepo orchestration for The Andb ecosystem. This repository manages the high-level project structure, documentation (`plans/`), and docker configurations, while source code resides in separate "poly" repositories.

⚠️ **Proprietary Software Notice** ⚠️

This project is **Source-Available** but **NOT Open Source**.
You are free to view, evaluate, and test this software locally, but strict commercial restrictions apply.
See [LICENSE](./LICENSE) and [COMMERCIAL.md](./COMMERCIAL.md) for details.

---

## ⚡ Quickstart (5 Minutes to First Diff)

The fastest way to experience The Andb's semantic diffing is by comparing the bundled test databases using the CLI.

### 1. Build & Link the Tooling

Assuming you have cloned the sub-repositories (see Setup Instructions below), build the core engine and link the CLI:

```bash
cd andb-core && npm install && npm run build && npm link && cd ..
cd andb-cli && npm install && npm link @the-andb/core && npm link && cd ..
```

### 2. Start Test Databases

Spin up the pre-configured MySQL Docker containers:

```bash
docker-compose -f docker/docker-compose.yml up -d
```

_(This starts `mysql-dev` on port 3307 and `mysql-prod` on port 3310)_

### 3. Configure Connections

Create an `andb.yaml` file in your root folder with the connection details:

```yaml
getDBDestination:
  dev:
    host: "127.0.0.1"
    port: 3307
    database: "andb_dev"
    username: "root"
    password: "root"
    type: "mysql"
  prod:
    host: "127.0.0.1"
    port: 3310
    database: "andb_prod"
    username: "root"
    password: "root"
    type: "mysql"
```

### 4. Run Your First Diff!

Use the CLI to compare the `dev` database against `prod`:

```bash
andb compare dev prod
```

> [!TIP]
> **Clean Pipe CLI**: The CLI separates informational logs (`stderr`) from data output (`stdout`). You can safely pipe the output to a file: `andb compare dev prod > result.sql`.

## 📂 Repository Structure

This project follows a **Polyrepo** structure managed under a single root directory.

| Directory         | Description                         | Git Repository                                                    |
| ----------------- | ----------------------------------- | ----------------------------------------------------------------- |
| **`ui/`**         | Desktop Application (Electron/Vue)  | [The-Andb/andb-desktop](https://github.com/The-Andb/andb-desktop) |
| **`core/`**       | Core Database Engine (**Zero-Dep**) | [The-Andb/andb-core](https://github.com/The-Andb/andb-core)       |
| **`cli/`**        | Command Line Tool (**Nest-Free**)   | [The-Andb/andb-cli](https://github.com/The-Andb/andb-cli)         |
| **`mcp/`**        | MCP Server (AI-Driven Schema Ops)   | [The-Andb/andb-mcp](https://github.com/The-Andb/andb-mcp)         |
| **`landing/`**    | Marketing Website                   | [The-Andb/andb-www](https://github.com/The-Andb/andb-www)         |
| **`andb-plans/`** | Documentation, Specs, and Roadmaps  | _Tracked in root_                                                 |
| **`docker/`**     | Infrastructure (Docker Compose)     | _Tracked in root_                                                 |

---

## ⚖️ License & Usage

**The Andb Public License (APL-1.0)**

- ✅ **Allowed**: View source, Clone repo, Run locally for evaluation/education.
- ❌ **Prohibited**: Commercial use, SaaS hosting, Redistribution, Forking for public competition.

For commercial licenses, please contact: `ph4n4n@gmail.com`

---

## 🚀 Setup Instructions

### 1. Clone the Root Hierarchy

```bash
git clone https://github.com/The-Andb/andb-monorepo.git The-Andb
cd The-Andb
```

### 2. Checkout Sub-modules

Run the following commands to populate the ignored sub-directories with their respective source code.

```bash
# UI (The Main App)
git clone https://github.com/The-Andb/andb-desktop.git andb-desktop

# Core (The Library)
git clone https://github.com/The-Andb/andb-core.git andb-core

# CLI (The Tooling)
git clone https://github.com/The-Andb/andb-cli.git andb-cli

# MCP Server
git clone https://github.com/The-Andb/andb-mcp.git andb-mcp

# Landing Page (WWW)
git clone https://github.com/The-Andb/andb-www.git andb-www
```

---

## 🔗 Local Development (Symlinking)

Since `ui` and `cli` depend on `core`, you need to link them locally to test changes immediately.

### Step 1: Build & Link Core

First, make sure `andb-core` is built and registered globally on your machine.

```bash
cd andb-core
npm install
npm run build      # IMPORTANT: Changes must be built to be visible
npm link           # Registers '@the-andb/core' symlink globally
cd ..
```

### Step 2: Consumer Projects (andb-desktop & andb-cli)

Link the local version of core into the consumer projects.

**For Desktop UI:**

```bash
cd andb-desktop
npm link @the-andb/core
```

**For CLI:**

```bash
cd andb-cli
npm link @the-andb/core
```

### 💡 Workflow Tips

- **Watch Mode**: If you are actively editing `core`, run `npm run build -- --watch` (or tsc watch) in the `core/` directory so changes are auto-compiled.
- **Re-linking**: If you run `npm install` in `ui` or `cli`, the symlink might be wiped out. You may need to run `npm link @the-andb/core` again.
- **Verification**: Check if the link is active:
  ```bash
  ls -l ui/node_modules/@the-andb/core
  # Should point to -> ../../../core
  ```

---

## 🐳 Database Initialization (Docker)

To spin up local test databases (MySQL & PostgreSQL) with pre-seeded data for various environments (dev, stage, uat, prod).

### 1. Start Services

Run the following command from the **root** directory:

```bash
# Start MySQL services
docker-compose -f docker/docker-compose.yml up -d

# Start PostgreSQL services (if needed)
docker-compose -f docker/docker-compose-postgres.yml up -d
```

### 2. Verify Containers

Check if the database containers are running:

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
```

You should see services like `mysql-dev`, `mysql-prod`, `postgres-dev`, etc.

### 3. Connection Details

Default credentials for local testing:

| Environment | Service Name | Port (MySQL) | Port (Postgres) | User                | Password            | Key DB Name  |
| ----------- | ------------ | ------------ | --------------- | ------------------- | ------------------- | ------------ |
| **Dev**     | `*-dev`      | 3307         | 5433            | `root` / `postgres` | `root` / `postgres` | `andb_dev`   |
| **Stage**   | `*-stage`    | 3308         | 5434            | `root` / `postgres` | `root` / `postgres` | `andb_stage` |
| **UAT**     | `*-uat`      | 3309         | 5435            | `root` / `postgres` | `root` / `postgres` | `andb_uat`   |
| **Prod**    | `*-prod`     | 3310         | 5436            | `root` / `postgres` | `root` / `postgres` | `andb_prod`  |

_Note: Data is automatically initialized using scripts in `docker/init-*.sql`._
