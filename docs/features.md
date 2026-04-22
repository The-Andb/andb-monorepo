# TheAndb Feature Guide

## 🗺️ Workspace Modules

### 1. Global Schema Search
Search through thousands of tables, views, and procedures across all your environments (DEV, STAGE, PROD) instantly. Powered by SQLite indexing.

### 2. Live-State Comparison
Compare structural differences between two live databases. Unlike traditional migration tools, Andb doesn't just rely on history files—it looks at the actual state of your schemas.

### 3. AI-DBA Assistant
A persistent, context-aware companion that lives in your sidebar. It can:
- **Audit DDL**: Find security risks and performance bottlenecks.
- **Optimize Indexes**: Suggest the best indexing strategy based on table structure.
- **Explain Systems**: Help you understand complex inheritance or FK relationships.

### 4. Semantic Diffs
See exactly what changed in your schema with color-coded, human-readable diffs that filter out formatting noise.

### 5. CLI & CI/CD
The `@the-andb/cli` allows you to integrate schema reliability checks directly into your GitHub Actions or GitLab pipelines.

### 6. MCP Server
Connect TheAndb to AI agents like Claude or ChatGPT to perform safe schema audits using the Model Context Protocol.
