# Model Context Protocol (MCP) Guide for TheAndb

TheAndb provides an MCP server that allows AI agents (like Claude Desktop or this internal assistant) to interact with your databases and workspace.

## Available Tools

### Database Introspection
- `list_schema_objects`: List tables, views, and triggers in a database.
- `get_object_ddl`: Retrieve the DDL (SQL) for a specific database object.
- `get_db_status`: Get basic statistics and status of a connection.

### Schema Analysis
- `compare_schema`: Compare two environments (e.g., STAGE vs PROD) and generate a diff.
- `diff_semantic`: Perform an AI-powered semantic comparison of schemas.
- `suggest_indexes`: Analyze query patterns or table structures to suggest performance optimizations.
- `analyze_ddl_risk`: Check if a SQL statement might cause downtime or lock issues.

### Project & Workspace Management
- `get_workspace_summary`: Returns a list of all projects and environments in your vault (now synchronized with Desktop GUI).
- `app_switch_project`: Switch the active project in the Desktop app.
- `app_create_project`: Create a new project to organize your databases.
- `export_schema`: Save the entire database schema to a file.
- `app_navigate`: Move between views like Dashboard, Settings, or Global Schema.

## How to use with Claude Desktop

To use TheAndb MCP with Claude Desktop, add the following to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "the-andb": {
      "command": "npx",
      "args": ["-y", "@the-andb/mcp", "start", "--vault-path", "/path/to/your/andb-vault"]
    }
  }
}
```

## Tips for AI Interactions
- Always ask for a `workspace_summary` first if you are unsure which projects are available.
- Use `diff_semantic` when comparing complex schema changes to get a human-readable explanation of "why" things changed.
- Run `analyze_ddl_risk` before applying any migration to ensure safety.
