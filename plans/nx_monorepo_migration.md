# Kế hoạch Migrate TheAndb lên Nx Monorepo 🚀

**Mục đích:** Tích hợp `andb-core`, `andb-cli`, `andb-desktop`, `andb-mcp` và `andb-www` vào một Monorepo chuyên nghiệp (Nx) để:
1. Share code (`andb-core`) mượt mà giữa các app không cần build đi build lại hay tạo symlink bằng cơm.
2. Quản lý Dependency Graph rõ ràng (Desktop gọi Core thoải mái, cấm Core gọi ngược lên Desktop).
3. Đóng gói & Release tự động cho từng package (`@the-andb/core`, `@the-andb/cli`) ra NPM một cách chuyên nghiệp.
4. Tận dụng Execution Caching vô địch của Nx (build lại chỉ tốn 0.5s nếu code không đổi).

---

## 📅 Lộ trình các bước (Migration Phases)

### Phase 1: Chuẩn bị & Setup Nx (The Foundation 🏗)
- [ ] Chạy lệnh `npx create-nx-workspace@latest the-andb-monorepo --preset=ts` hoặc cài init vào base repo.
- [ ] Config `tsconfig.base.json` cho toàn bộ dự án để map path aliases (VD: `@the-andb/core` -> `libs/core/src/index.ts`).
- [ ] Setup rule Lint (ESLint + Prettier) và Format chung cho nguyên bầy monorepo.

### Phase 2: Migrate Core Engine (The Brain 🧠)
- [ ] Move toàn bộ source code của `andb-core` vào thư mục `libs/core`.
- [ ] Refactor lại các file `index.ts` exported từ `andb-core` để chuẩn bị cho publish.
- [ ] Setup Nx executor cho việc compile TS của `core` ra chuẩn ESM + CJS.

### Phase 3: Migrate CLI & MCP (The Workers 👷‍♂️)
- [ ] Move `andb-cli` vào thư mục `apps/cli` (hoặc `apps/andb`).
- [ ] Gắn dependency từ `apps/cli` gọi sang `libs/core`.
- [ ] Cấu hình ESBuild (nhanh hơn TSC) để bundle file thực thi `bin/andb.js` cho CLI và MCP.
- [ ] Chỉnh CLI để nó tự dev-watch và run thay vì phải ts-node lạch cạch.

### Phase 4: Migrate Desktop (The Final Boss 💥)
- [ ] Move `andb-desktop` vào thư mục `apps/desktop`.
- [ ] Gỡ bỏ những path relative cực hình kiểu `import { ... } from '../../andb-core'`.
- [ ] Thay máu toàn bộ import gọi `Core` thành `import { ... } from '@the-andb/core'`.
- [ ] Cấu hình bộ Executor của Nx Vite + Electron để build cả Main và Renderer song song. *Lưu ý: Khúc này là xương máu nhất, dễ config fail nhất.*

### Phase 5: CI/CD & Publishing (The Glorious Exit 🌟)
- [ ] Set up GitHub Actions chạy Nx Release.
- [ ] Cấu hình nx affected để PR trên GitHub tự detect sửa gói nào build/test gói đó.
- [ ] Release version 4.0.0 đồng loạt trên NPM và Github Releases.

---

### ☠️ Cảnh báo & Rủi ro khi làm (Roast Notes)
1. **Config Hell:** Chuyển Vite + Electron + Nx là combo đắt giá nhưng tốn nhiều nơ-ron cấu hình. Nếu fail nhiều cứ chửi Nx documentation, đừng hoảng hốt.
2. **Context Loss:** Hạn chế làm Nx chung với việc sửa logic của Core. Cứ phải khoá tính năng (Freeze features) chừng 1-2 ngày cuối tuần để bê nhà.
3. **Patience Required:** Nx bắt ép strict boundaries, nếu trong `andb-core` vô tình import ngược thư viện của UI, Nx nó sẽ cạch mặt không cho build.

> *"Đã chơi là chơi cho tới bến, Monorepo xịn nó tự xé vé nâng tầm dự án anh em lên đẳng cấp open-source tier nghìn sao."*
