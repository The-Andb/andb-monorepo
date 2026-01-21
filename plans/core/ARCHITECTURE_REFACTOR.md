# Architecture Refactor: Pluggable Storage Layer

## Tổng quan

Refactor andb-core để support cả file-based (CLI) và database-based (Electron) storage thông qua pluggable DataStore pattern.

## Vấn đề ban đầu

**CLI-only architecture:**
```
Export → Write files (.list, .sql) 
       → Compare reads files 
       → Write comparison files 
       → Electron reads back files
```

**Issues:**
- Electron userData path permissions phức tạp
- File I/O overhead
- Không tối ưu cho GUI app
- Tight coupling với filesystem

## Giải pháp: Pluggable Storage

### 1. DataStore Abstraction (`core/utils/data.store.js`)

```javascript
// Base interface
class DataStore {
  async saveExport(env, database, type, data) {}
  async getExport(env, database, type) {}
  async getDDLList(env, database, type) {}
  async saveComparison(srcEnv, destEnv, database, type, results) {}
  async getComparison(srcEnv, destEnv, database, type) {}
}

// FileStore - For CLI (backward compatible)
class FileStore extends DataStore {
  // Uses existing FileManager
  // Reads/writes .list and .sql files
}

// MemoryStore - For Electron
class MemoryStore extends DataStore {
  // In-memory Map storage
  // No filesystem dependencies
  // Can sync to electron-store
}
```

### 2. Core Services Updates

**ExporterService:**
- ✅ Collect exported data (tables, procedures, functions)
- ✅ Return `{count, data}` instead of just count
- ✅ Save to DataStore (if provided)
- ✅ Still write files if `enableFileOutput = true`

**ComparatorService:**
- ✅ Read from DataStore first
- ✅ Fallback to files if DataStore not available
- ✅ Support both storage modes

**Container:**
- ✅ Inject DataStore into services
- ✅ Default to FileStore (backward compatible)
- ✅ Accept custom DataStore from config

### 3. Configuration

**CLI (existing, no changes):**
```javascript
const config = {
  baseDir: process.cwd(),
  enableFileOutput: true,  // default
  // dataStore: undefined → uses FileStore
}
```

**Electron (new):**
```typescript
const config = {
  baseDir: app.getPath('userData'),
  enableFileOutput: false,  // No file output needed
  dataStore: new MemoryStore()  // In-memory storage
}
```

## Benefits

### ✅ Backward Compatible
- CLI works exactly as before
- No breaking changes
- Files still generated for git tracking

### ✅ Electron Optimized
- No filesystem dependencies
- In-memory operations (fast)
- Can sync to electron-store for persistence
- No permission issues

### ✅ Clean Architecture
- Separation of concerns
- Pluggable storage
- Easy to add new adapters (SQLite, PostgreSQL, etc)

### ✅ Dual Mode
- Files: CLI, git tracking, audit trail
- Database: Electron, performance, reliability

## Data Flow

### Export Operation

**CLI:**
```
DB → Query → ExporterService 
           → Write files (.list, .sql)
           → FileStore (reads files back)
           → Return data
```

**Electron:**
```
DB → Query → ExporterService 
           → MemoryStore.saveExport()
           → Return data (no files)
```

### Compare Operation

**CLI:**
```
ExporterService → Files → ComparatorService 
                       → Read files
                       → Compare logic
                       → Write comparison files
                       → Return results
```

**Electron:**
```
ExporterService → MemoryStore → ComparatorService 
                              → Read from MemoryStore
                              → Compare logic (in-memory)
                              → Save to MemoryStore
                              → Return results
```

## Implementation Summary

### Files Changed

**Core (`andb-core/`):**
- ✅ `core/utils/data.store.js` - NEW: DataStore abstraction
- ✅ `core/service/exporter.js` - Return data + save to DataStore
- ✅ `core/service/comparator.js` - Read from DataStore
- ✅ `core/service/container.js` - Inject DataStore

**Electron UI (`andb-ui/`):**
- ✅ `electron/services/andb-builder.ts` - Pass MemoryStore to config

### API Changes

**ExporterService methods now return:**
```javascript
// Before:
return tableResults.length  // number

// After:
return {
  count: tableResults.length,
  data: [{ name, ddl }, ...]
}
```

**Config accepts new options:**
```javascript
{
  enableFileOutput?: boolean,  // Optional file output
  dataStore?: DataStore        // Custom storage adapter
}
```

## Testing

**CLI:** Should work as before
```bash
cd andb-cli
npm test
```

**Electron:** 
```bash
cd andb-ui
npm run dev
# Test Export → Compare → Migrate flow
```

## Future Enhancements

- [ ] SQLite adapter for persistent storage
- [ ] PostgreSQL adapter for multi-user
- [ ] Redis adapter for distributed systems
- [ ] Compression for large DDL data
- [ ] Encryption for sensitive data

## Migration Guide

### For CLI Users
No changes needed. Everything works as before.

### For Electron/GUI Apps
```typescript
import { MemoryStore } from '@andb/core/core/utils/data.store'

const config = {
  ...otherConfig,
  enableFileOutput: false,
  dataStore: new MemoryStore()
}
```

### For Custom Implementations
Implement DataStore interface:
```javascript
class MyCustomStore extends DataStore {
  async saveExport(env, database, type, data) {
    // Your implementation
  }
  // ... other methods
}
```

---

**Status:** ✅ Completed  
**Date:** 2024-11-21  
**Impact:** Core architecture + Electron UI  
**Breaking Changes:** None (backward compatible)

