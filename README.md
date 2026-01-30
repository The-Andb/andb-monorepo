# Andb Main Hierarchy

Monorepo orchestration for the Andb ecosystem. This repository manages the high-level project structure, documentation (`plans/`), and docker configurations, while source code resides in separate "poly" repositories.

⚠️ **Proprietary Software Notice** ⚠️

This project is **Source-Available** but **NOT Open Source**.
You are free to view, evaluate, and test this software locally, but strict commercial restrictions apply.
See [LICENSE](./LICENSE) and [COMMERCIAL.md](./COMMERCIAL.md) for details.

## 📂 Repository Structure

This project follows a **Polyrepo** structure managed under a single root directory.

| Directory         | Description                          | Git Repository                                                    |
| ----------------- | ------------------------------------ | ----------------------------------------------------------------- |
| **`ui/`**         | Desktop Application (Electron/Vue)   | [The-Andb/andb](https://github.com/The-Andb/andb)                 |
| **`core/`**       | Core Database Engine (Logic/Drivers) | [The-Andb/andb-core](https://github.com/The-Andb/andb-core)       |
| **`cli/`**        | Command Line Tool                    | [The-Andb/andb-cli](https://github.com/The-Andb/andb-cli)         |
| **`landing/`**    | Marketing Website                    | [The-Andb/andb-landing](https://github.com/The-Andb/andb-landing) |
| **`andb-plans/`** | Documentation, Specs, and Roadmaps   | _Tracked in root_                                                 |
| **`docker/`**     | Infrastructure (Docker Compose)      | _Tracked in root_                                                 |

---

## ⚖️ License & Usage

**The Andb Public License (APL-1.0)**

- ✅ **Allowed**: View source, Clone repo, Run locally for evaluation/education.
- ❌ **Prohibited**: Commercial use, SaaS hosting, Redistribution, Forking for public competition.

For commercial licenses, please contact: `licensing@andb.dev`

---

## 🚀 Setup Instructions

### 1. Clone the Root Hierarchy

```bash
git clone https://github.com/The-Andb/main-hierarchy.git The-Andb
cd The-Andb
```

### 2. Checkout Sub-modules

Run the following commands to populate the ignored sub-directories with their respective source code.

```bash
# UI (The Main App)
git clone https://github.com/The-Andb/andb.git ui

# Core (The Library)
git clone https://github.com/The-Andb/andb-core.git core

# CLI (The Tooling)
git clone https://github.com/The-Andb/andb-cli.git cli

# Landing Page
git clone https://github.com/The-Andb/andb-landing.git landing
```

---

## 🔗 Local Development (Symlinking)

Since `ui` and `cli` depend on `core`, you need to link them locally to test changes immediately.

### Step 1: Build & Link Core

First, make sure `core` is built and registered globally on your machine.

```bash
cd core
npm install
npm run build      # IMPORTANT: Changes must be built to be visible
npm link           # Registers '@the-andb/core' symlink globally
cd ..
```

### Step 2: Consumer Projects (UI & CLI)

Link the local version of core into the consumer projects.

**For UI:**

```bash
cd ui
npm link @the-andb/core
```

**For CLI:**

```bash
cd cli
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
