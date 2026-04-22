# TheAndb Technical Architecture

## 📦 Package Ecosystem
- **@the-andb/core**: The stateless business logic library (Brain).
- **@the-andb/cli**: Terminal utilities for developers and CI/CD.
- **andb-desktop**: Passive Electron GUI (Electron + Vue).
- **andb-mcp**: MCP server for AI integration.

## 💾 Storage Mechanisms
TheAndb uses a flexible storage strategy depending on the environment:
- **FileStorage**: Direct `.sql` file manipulation (ideal for Git).
- **SQLiteStorage**: Indexed local database (`andb-storage.db`) for high-performance UI filtering.
- **HybridStorage**: Combines the speed of SQLite with the persistence of the file system.

## 🛠️ Tech Stack
- **Languages**: TypeScript, HTML, CSS.
- **Frameworks**: Vue 3 (Desktop UI), TypeORM (Storage).
- **Platform**: Electron (Cross-platform desktop).
- **Database**: SQLite (Internal state management).
- **AI**: Gemini 1.5 Pro / Flash.
