# 🗺️ TheAndb - Sprint Plan (Feb 2026)

> Living document — Updated: Feb 05, 2026

## Current Focus: SSH Integration & Distribution

---

### ✅ Recently Completed

- [x] **SSH Tunneling in Core**: Migrated SSH logic from UI to Core (`ssh-tunnel.ts`)
- [x] **MysqlDriver SSH Support**: Auto-detect and establish tunnel before DB connection
- [x] **OrchestrationService**: Map UI ssh config → Core ISshConfig, read privateKeyPath
- [x] **Restricted User Setup (SCA)**: Full Auto/Manual flow with verification suite

---

### 🚧 In Progress (This Week)

#### 1. Distribution & Build

- [ ] **macOS Build**: Configure `electron-builder` for v3.1.0 release
- [ ] **Code Signing**: Apple Developer cert integration
- [ ] **Auto-Update**: Test Squirrel/electron-updater flow

#### 2. Connection UX Polish

- [ ] **Template SSH Form**: Add SSH fields to `ConnectionTemplateManager.vue`
- [ ] **Test Connection via SSH**: Validate SSH tunnel in test-connection flow
- [ ] **Error Messages**: Improve SSH-specific error handling (key not found, auth failed)

#### 3. Core Stability

- [ ] **Session Hygiene**: Standardize `utf8mb4`, timezone on connect
- [ ] **Connection Timeout**: Implement configurable timeout for SSH + DB
- [ ] **Retry Logic**: Basic retry for transient network errors

---

### 📅 Next Sprint (Feb 10-17)

| Task                      | Priority | Notes                             |
| ------------------------- | -------- | --------------------------------- |
| PostgreSQL Driver (Spike) | High     | Research pg introspection queries |
| Windows Build             | Medium   | electron-builder Windows config   |
| Linux AppImage            | Low      | Test on Ubuntu 22.04              |

---

### ⚠️ Blockers & Risks

- **SSH Key Permissions**: Cross-platform file access for private keys in Electron
- **macOS 26 Compatibility**: Electron 28.x SIGTRAP issue (needs testing)
- **Large Schema Performance**: 5000+ table stress test pending

---

### 📝 Notes

- SSH logic now fully in Core → UI chỉ gửi config, không xử lý connect
- Cần test SSH tunnel với Docker openssh-server (đã setup trong `docker/`)
- Sắp tới cần refactor `DriverFactory` để inject sshConfig cleaner
