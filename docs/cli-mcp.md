# TheAndb CLI & MCP Documentation

## 💻 Command Line Interface (CLI)
The project provides a powerful CLI (`andb`) for developers and CI/CD pipelines.

### Core Commands
- **`andb compare <src> <dest>`**: Compare schema differences between two environments.
- **`andb export <env>`**: Export the current state of a database to a DDL snapshot.
- **`andb plan <src> <dest>`**: Generate a migration plan based on detected differences.
- **`andb vault migrate`**: Perform maintenance on the local database vault.

### Configuration
Project settings are managed via `andb.yaml`. You can configure:
- **Environments**: DEV, STAGING, PRODUCTION URLs.
- **Policies**: Safety rules for destructive operations.

## 🤖 Model Context Protocol (MCP)
TheAndb includes an MCP server to integrate its database intelligence into AI agents like Claude Desktop or ChatGPT.

### Server Configuration
To use the MCP server, add it to your agent's config file:

```json
{
  "mcpServers": {
    "the-andb": {
      "command": "node",
      "args": ["/path/to/andb-mcp/dist/index.js"]
    }
  }
}
```

### Capabilities
When active, the AI agent can:
- **`list_tables`**: See all tables in the current project context.
- **`get_table_ddl`**: Retrieve the exact schema for any table.
- **`compare_schemas`**: Perform its own semantic analysis of drift between environments.
- **`audit_safety`**: Run automated checks for risky SQL operations.
