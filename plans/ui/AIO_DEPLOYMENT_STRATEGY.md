# Tiêu chuẩn: AIO Deployment Strategy (All-In-One)

Tài liệu này định nghĩa chiến lược đóng gói và phát hành (hoàn toàn tách bạch) cho hệ sinh thái The Andb, đảm bảo Desktop App không bị trói buộc vòng đời phiên bản với Core Package trên NPM.

## 1. Mục tiêu kiến trúc (Goals)

1. **Desktop Độc Lập**: Ứng dụng Desktop (`andb-desktop`) phải chứa đủ mọi luồng xử lý bên trong chính nó khi build ra bản Production (`.dmg`, `.exe`), không bao giờ gọi hay phụ thuộc vào `node_modules` bên ngoài hoặc thư viện `@the-andb/core` tải từ internet.
2. **Release Độc Lập**: Gói `@the-andb/core` có thể được nâng cấp, phá vỡ (breaking changes), bóp méo và publish lên NPM hàng ngày (v4, v5, v6...) mà không làm chết ứng dụng Desktop đang chạy bản ổn định cũ.
3. **Phát triển Liền mạch (Dev DX)**: Trong lúc code ở môi trường Local, nếu dev sửa 1 dòng trong `andb-core`, bên `andb-desktop` phải nhận được ngay lập tức mà không cần copy hay build lại packages thủ công.

---

## 2. Giải pháp kỹ thuật

Chiến lược này kết hợp 3 lớp công nghệ: **[1] PNPM Workspaces**, **[2] ESBuild AIO Bundling**, và **[3] Electron-Builder Exclusions**.

### 2.1. Lớp Phát triển (Local Development) - Cơ chế "Workspace Symlink"
- **Không copy thủ công**: PNPM được cấu hình qua `pnpm-workspace.yaml`. Tại `andb-cli/package.json` và `andb-desktop/package.json`, phiên bản của core được fix cứng là `"@the-andb/core": "workspace:*"`.
- **Luồng hoạt động**: Khi cài đặt, PNPM không tải '@the-andb/core' từ mạng, mà trực tiếp tạo một liên kết mềm (symlink) từ `node_modules/@the-andb/core` trỏ thẳng tới thư mục gốc `../andb-core`.
- **Kết quả**: Bất kỳ thay đổi code nào trong thư mục `andb-core` sẽ ngay lập tức có hiệu lực cho Desktop và CLI ở chế độ Local Dev.

### 2.2. Lớp Đóng gói (Production Build) - Cơ chế "ESBuild AIO"
Lớp này cắt đứt hoàn toàn dây dưa với hệ thống phân giải module của Node.js (Node Resolution).

- **Main Process (Desktop)**: Dùng script `esbuild` (`scripts/build-electron.mjs`) thay cho `tsc` thông thường. ESBuild sẽ nuốt trọn bộ `electron/main.ts` CÙNG VỚI mọi thứ nó import (bao gồm `@sentry/electron`, `@the-andb/core` - lúc này đang là symlink local) và compile tất cả thành ĐÚNG 1 tệp tin `dist-electron/main.js` vật lý, tự cung tự cấp.
- **CLI & MCP (Các Background Workers)**: Tương tự Desktop Main Process, `andb-cli` cũng được build móp lại thành một khối tĩnh (`dist/index.js`), chứa sẵn toàn bộ mã nguồn của `@the-andb/core` tại thời điểm build.
- **Kết quả**: Cả Desktop App và CLI Binary giờ đây biến thành các ứng dụng chạy độc lập (Standalone), chứa luôn bản snapshot của Core lúc build vào bộ nhớ tĩnh.

### 2.3. Lớp Giao Phân phối (Distribution) - Nhẹ hoá DMG
Tận dụng kết quả của Lớp 2.2, file App (`app.asar`) cuối cùng không còn cần hệ sinh thái NPM nữa.

- **Cấu hình Electron-Builder**: Trong `andb-desktop/package.json`, mảng `"files"` được thêm cấu hình `"!node_modules"`.
- **Luồng hoạt động**: Khi build `.dmg`, Electron-Builder sẽ vứt toàn bộ thư mục `node_modules` (lên tới cả gb) vào thùng rác, chỉ copy folder `dist/` (UI tĩnh), `dist-electron/main.js` (AIO Backend) và copy `andb-cli` qua `"extraResources"`.
- **Kết quả**: DMG xuất ra với dung lượng tối giản tuyệt đối (~100-200MB thay vì ~800MB), và vì `app.asar` không chứa `@the-andb/core` version NPM, ứng dụng sẽ chạy độc lập và an định đến vĩnh viễn.

### 2.4. Cấu trúc thư mục sau khi đóng gói (Post-Build Structure)
Người dùng sẽ nhận được file `The-Andb.app` (trên máy Mac) với cấu trúc ruột hoàn toàn tinh gọn, **không có bóng dáng của `node_modules`**:

```text
The Andb.app/Contents/Resources/
├── app.asar/                      # ← Gói mã nguồn chính của Desktop App
│   ├── dist/                      # UI Frontend (đã nén bởi Vite)
│   ├── dist-electron/             # Backend (đã nén bởi ESBuild thành 1 cục)
│   │   └── main.js                # Chứa Sentry, Core logic, Electron events
│   └── package.json               # Cấu hình app gốc
│
├── app.asar.unpacked/             # ← Chứa các binary chạy native
│   └── node_modules/              # CHỈ CHỨA DUY NHẤT các thư viện C++ (Native bindings)
│       └── better-sqlite3/        # vd: sqlite3.node (bắt buộc unpack để chạy)
│
└── tools/                         # ← extraResources (Các Microservices/Tools)
    ├── andb-cli/                  
    │   └── andb.js                # CLI standalone binary (đã AIO core vào trong)
    └── andb-mcp/                  
        └── mcp.js                 # MCP standalone binary
```

---

## 3. Bản tóm tắt luồng công việc tương lai

Khi team triển khai update:

1. **Bug Fix & Core Feature**: Code thả ga trong `andb-core/`. Cứ lưu là Desktop & CLI dev mode tự nhận tự chạy.
2. **Core Release (Tuỳ ý)**: Chạy `npm run build:core` -> Update version -> `npm publish`. Publish bao nhiêu bản tuỳ thích cho cộng đồng xài qua NPM, Desktop không hề quan tâm.
3. **Desktop Release**: Khi Desktop cần ra tính năng (vd bản 3.2.4):
   - Chạy lệnh build: `npm run desktop:publish`.
   - Lúc này script sẽ đi qua Lớp 2.2, hút cái source code mới nhất của `andb-core` local vào trong `main.js` và `andb-cli` binary.
   - Electron loại bỏ `node_modules`, thả binary vào DMG và bay thẳng lên GitHub Releases.

## 4. Tự kiểm tra Cấu trúc (Self-Check Rule)
Mô hình này hoàn toàn tuân thủ Rule số #1 và Rules Kiến trúc trong `.cursorrules`:
- Không Business Logic leak ra ngoài: Core code vẫn tách bạch ở `andb-core`.
- Không có rủi ro Side-effect: Symlink ở dev và Static Bundle ở prod đảm bảo 1 sự nhất quán duy nhất.

---

## 5. Nâng cấp Architecture (Bulletproof Production)

Mặc dù 3 lớp trên giải quyết triệt để vòng đời độc lập, hệ thống vẫn tiềm ẩn nguy cơ "Snapshot Drift" (mất dấu phiên bản Core khi debug) và thiếu tính toàn vẹn khi build. Để đạt mức "Production-Grade", các nâng cấp sau **bắt buộc phải được tích hợp**:

### 5.1. Version Trace & Build Manifest (Chống Snapshot Drift)
Khi Desktop gói Core vào một khối tĩnh, ta mất dấu hoàn toàn phiên bản NPM ban đầu. Nếu user báo lỗi, ta sẽ bị "mù" thông tin debug.
- **Giải pháp**: 
  - Tại compile-time, dùng ESBuild `define` để hardcode `__CORE_VERSION__`, `__CORE_COMMIT__`, và `__BUILD_TIME__` lấy từ thư mục `../andb-core/package.json` và lệnh `git rev-parse`.
  - Lúc Desktop khởi động, in thẳng metadata này ra log console đầu tiên.
  - Tự động sinh file `build-manifest.json` thả vào `app.asar` chứa bộ checksum và version matrix của toàn bộ hệ sinh thái lúc đóng gói.

### 5.2. Reproducible Builds (Build nhất quán tuyệt đối)
`workspace:*` là con dao hai lưỡi ở production. Lỡ lúc build CI/CD, có file local đang bị sửa dở, bản Desktop sẽ dính luôn mảng code rác đó.
- **Giải pháp**: 
  - Khóa chặt command build Desktop Production: Phải chạy lệnh lấy đúng commit (vd `git submodule update --init` hoặc `git checkout <tag>`) của Core.
  - Xài `pnpm install --frozen-lockfile` để tránh ma thuật văng version của NPM lúc resolve.

### 5.3. Bundle Verification Test (CI Gate)
ESBuild không phải viên đạn bạc với môi trường Node/Electron. Lỗi Native Modules (như `sqlite3.node`) hay dynamic `require()` có thể lọt qua build rất mượt mà vẫn làm crash app lúc Runtime.
- **Giải pháp**:
  - Không auto-publish ngay lặp tức. Sau bước `electron-builder`, tạo 1 bước script chạy Playwright (hoặc Node spawn) khởi động thử `dist-electron/main.js` dạng headless.
  - Assert xem hàm `Engine.init()` có boot thành công không. Pass vòng này mới được phép đính kèm lên GitHub Release.

### 5.4. Chiến lược "External CLI" (Decoupling Tuyệt đối)
Mặc định CLI nằm chung trong DMG. Nghĩa là CLI có bug mạng -> phải ép user tải lại nguyên cái DMG Desktop 150MB. Quá cồng kềnh.
- **Giải pháp Nâng cao**: 
  - Giống Docker Desktop, tách Desktop UI và Engine (`andb-cli`) làm 2 package publish riêng biệt trên GitHub Releases.
  - Lúc Desktop tải về, nó sẽ *tự động fetch* file binary `andb-cli` bản mới nhất (khớp checksum) về mục `Application Support`. 
  - Khi có hotfix cho `andb-core`, ta chỉ việc build lại `andb-cli.exe` và đẩy lên server. Desktop user khởi động lại app là tự húp bản patch Core mới chỉ tốn vài MB, không cần tải lại UI.
