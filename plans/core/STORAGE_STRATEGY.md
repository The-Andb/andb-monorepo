# Storage Strategy - SQLite + Files

## Overview

Refactor storage layer từ file-only sang pluggable strategy support SQLite + Files song song.

## Mapping: Folder Structure → SQLite Schema

### Current Folder Structure

```
db/
├── DEV/
│   └── dev_database/
│       ├── current-ddl/
│       │   ├── TABLES.list      → ddl_exports WHERE type='TABLES'
│       │   ├── PROCEDURES.list
│       │   ├── FUNCTIONS.list
|       |   └── TRIGGERS.list
│       ├── tables/
│       │   ├── users.sql        → ddl_exports (row)
│       │   └── orders.sql
│       └── backup/

map-migrate/
└── DEV-to-STAGE/
    └── dev_database/
        └── tables/
            ├── new.list         → comparisons WHERE status='new'
            ├── updated.list     → comparisons WHERE status='updated'
            └── deprecated.list  → comparisons WHERE status='deprecated'
```

### SQLite Tables

**1. ddl_exports** - Replaces `db/{env}/{db}/{type}/{name}.sql`
```sql
- environment: DEV, STAGE, UAT, PROD
- database_name: dev_database
- ddl_type: TABLES, PROCEDURES, FUNCTIONS
- ddl_name: users, orders
- ddl_content: Full DDL statement
- file_path: db/DEV/dev_database/tables/users.sql
- exported_to_file: 0=pending, 1=synced
```

**2. comparisons** - Replaces `map-migrate/{src}-to-{dest}/{db}/{type}/*.list`
```sql
- src_environment: DEV
- dest_environment: STAGE
- ddl_name: users
- status: new, updated, deprecated
- alter_statements: JSON array
- file_path: map-migrate/DEV-to-STAGE/dev_database/tables/new.list
```

## Storage Strategies

### 1. FileStorage (Default - Backward Compatible)

```javascript
const { FileStorage } = require('./utils/storage.strategy')
const storage = new FileStorage(fileManager, baseDir)

// Works exactly like before
await storage.saveDDL({
  environment: 'DEV',
  database: 'dev_database',
  type: 'TABLES',
  name: 'users',
  content: 'CREATE TABLE ...'
})
```

**Use case:** CLI, existing projects, git tracking

### 2. SQLiteStorage (New - High Performance)

```javascript
const { SQLiteStorage } = require('./utils/storage.strategy')
const storage = new SQLiteStorage('./andb.db', baseDir)

// Fast DB operations
await storage.saveDDL(...)  // Instant write to SQLite

// Export to files when needed
await storage.exportToFiles()  // Generate files for git
```

**Use case:** Electron, large datasets, complex queries

### 3. HybridStorage (Recommended)

```javascript
const { HybridStorage, SQLiteStorage, FileStorage } = require('./utils/storage.strategy')

const sqlite = new SQLiteStorage('./andb.db', baseDir)
const files = new FileStorage(fileManager, baseDir)
const storage = new HybridStorage(sqlite, files, autoExport = false)

// Write to SQLite (fast)
await storage.saveDDL(...)

// Manually export to files
await storage.exportToFiles()

// Or auto-export
const autoStorage = new HybridStorage(sqlite, files, autoExport = true)
await autoStorage.saveDDL(...)  // Writes to both
```

**Use case:** Production, best of both worlds

## Integration with Core

### Container Configuration

```javascript
// andb-core/core/service/container.js

createStorage() {
  this.services.set(STORAGE, (container) => {
    const baseDir = container.get(BASE_DIR)
    const fileManager = container.get(FILE_MANAGER)
    
    // Choose storage based on config
    if (this.config.storage === 'sqlite') {
      const { SQLiteStorage } = require('../utils/storage.strategy')
      return new SQLiteStorage(this.config.storagePath || './andb.db', baseDir)
    }
    
    if (this.config.storage === 'hybrid') {
      const { HybridStorage, SQLiteStorage, FileStorage } = require('../utils/storage.strategy')
      const sqlite = new SQLiteStorage(this.config.storagePath || './andb.db', baseDir)
      const files = new FileStorage(fileManager, baseDir)
      return new HybridStorage(sqlite, files, this.config.autoExport)
    }
    
    // Default: FileStorage (backward compatible)
    const { FileStorage } = require('../utils/storage.strategy')
    return new FileStorage(fileManager, baseDir)
  })
  return this
}
```

### Usage in Services

```javascript
// exporter.js
async exportTables(connection, dbConfig) {
  // ... query database ...
  
  for (const tableName of tables) {
    await this.storage.saveDDL({
      environment: dbConfig.envName,
      database: this.getDBName(dbConfig.envName),
      type: 'TABLES',
      name: tableName,
      content: createStatement
    })
  }
  
  // Optional: Export to files
  if (this.config.exportFiles) {
    await this.storage.exportToFiles()
  }
}

// comparator.js
async loadDDLContent(srcEnv, destEnv, ddlType) {
  const srcLines = await this.storage.getDDLList(srcEnv, this.getDBName(srcEnv), ddlType)
  const destLines = await this.storage.getDDLList(destEnv, this.getDBName(destEnv), ddlType)
  return { srcLines, destLines }
}
```

## Configuration Examples

### CLI (File-based, default)

```javascript
// andb.config.js
module.exports = {
  storage: 'file',  // or undefined (default)
  baseDir: process.cwd()
}
```

### Electron (SQLite-based)

```typescript
// andb-builder.ts
const config = {
  storage: 'sqlite',
  storagePath: path.join(app.getPath('userData'), 'andb.db'),
  baseDir: app.getPath('userData'),
  autoExport: false  // Manual file export
}
```

### Production (Hybrid)

```javascript
module.exports = {
  storage: 'hybrid',
  storagePath: './data/andb.db',
  baseDir: process.cwd(),
  autoExport: false,  // Export to files on-demand
  exportFiles: true   // Enable file export in services
}
```

## Data Flow

### Write Operation (Hybrid Mode)

```
Export/Compare → HybridStorage.saveDDL()
                 ├─> SQLiteStorage.saveDDL() [instant]
                 └─> [autoExport=false] Queue for later
                 
Manual Export → storage.exportToFiles()
                └─> Generate files for git
```

### Read Operation (Hybrid Mode)

```
Service → HybridStorage.getDDL()
          ├─> Try SQLite first (fast)
          └─> Fallback to files (if SQLite empty)
```

## Benefits

### Performance
- **SQLite:** ~100x faster than file I/O
- **Indexed queries:** Instant lookups
- **Transactions:** ACID guarantees

### Reliability
- **No file locks:** Multi-process safe
- **No race conditions:** Database handles concurrency
- **Automatic rollback:** Transaction failures

### Flexibility
- **File export on-demand:** Only when needed
- **Backward compatible:** CLI works as before
- **Queryable:** SQL analytics on DDL history

### Git/Versioning
- **Files still generated:** `exportToFiles()`
- **Same format:** No breaking changes
- **On-demand:** Generate when pushing

## Migration Path

### Phase 1: Add SQLite Support (✅ Done)
- ✅ SQLite schema
- ✅ Storage strategies
- ✅ Container integration

### Phase 2: Refactor Services (Next)
- [ ] Update ExporterService to use storage
- [ ] Update ComparatorService to use storage
- [ ] Update MigratorService to use storage

### Phase 3: Testing
- [ ] Unit tests for strategies
- [ ] Integration tests CLI
- [ ] Integration tests Electron

### Phase 4: Deployment
- [ ] CLI: Keep FileStorage default
- [ ] Electron: Switch to HybridStorage
- [ ] Document migration guide

## API Reference

### StorageStrategy Interface

```javascript
class StorageStrategy {
  // Save DDL
  async saveDDL(data: {
    environment: string,
    database: string,
    type: string,
    name: string,
    content: string
  }): Promise<boolean>
  
  // Get DDL content
  async getDDL(environment, database, type, name): Promise<string>
  
  // Get DDL list (for .list files)
  async getDDLList(environment, database, type): Promise<string[]>
  
  // Save comparison
  async saveComparison(comparison: {
    srcEnv, destEnv, database, type, name, status, ...
  }): Promise<boolean>
  
  // Get comparisons
  async getComparisons(srcEnv, destEnv, database, type): Promise<Object[]>
  
  // Export to files
  async exportToFiles(): Promise<{success, filesExported}>
}
```

## Troubleshooting

### "Database locked" error
- Use WAL mode: `PRAGMA journal_mode=WAL`
- Close connections properly
- Use transactions for batch operations

### Files not synced
- Call `storage.exportToFiles()` manually
- Or enable `autoExport: true`

### Performance issues
- Create indexes on common queries
- Use transactions for bulk operations
- Consider batch export instead of auto

---

**Status:** ✅ Architecture complete  
**Next:** Integrate into services  
**Impact:** Core storage layer  
**Breaking:** None (backward compatible)

