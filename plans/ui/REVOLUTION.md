# UI/UX SPECIFICATION: DDL REVOLUTION (NAVICAT STYLE)

## 1. TRIẾT LÝ THIẾT KẾ (DESIGN PHILOSOPHY)

- **Minimalism & Clean:** Loại bỏ mọi thành phần rườm rà, tập trung vào dữ liệu so sánh.
- **Source-Centric Navigation:** Sidebar chỉ quản lý Source để giảm tải thị giác.
- **Mirror Sync:** Hai bên luôn soi gương nhau, tự động căn chỉnh vị trí.

---

## 2. CẤU TRÚC LAYOUT TỔNG THỂ

Giao diện chia thành 2 vùng chính:

### A. Sidebar (Bên trái) - Điều hướng Nguồn

- **Grouping:** Phân nhóm theo `Environment` (Local, Dev, Staging, Prod).
- **Visibility:** Chỉ hiển thị cây thư mục của **Source Environment**.
- **Tính năng:** Mở/đóng cây thư mục để chọn Object (Table, View, Proc, Func).
- **Settings:** Icon bánh răng nằm cố định góc dưới Sidebar để cấu hình kết nối.

### B. Main Pane (Trung tâm) - CompareView

Chia đôi màn hình theo chiều dọc (Split-view):

- **Cột Trái (Mirror Source):** Hiển thị DDL của Source.
- **Cột Phải (Mirror Destination):** Hiển thị DDL tương ứng của Destination.

---

## 3. LOGIC ĐIỀU HƯỚNG & ĐỒNG BỘ (SYNC LOGIC)

### 3.1. Auto-Sync Tree View

- Khi người dùng click chọn 1 Object ở Sidebar (Source):
  - Hệ thống tự động tìm Object tương ứng ở Destination.
  - Cả hai khung hình Source và Destination cùng cuộn đến vị trí đó đồng thời.

### 3.2. Empty Placeholders (Xử lý lệch DDL)

Để đảm bảo hai bên luôn "soi gương" chuẩn xác, các khoảng trống được lấp đầy bằng Placeholder:

- **Trường hợp New DDL (Chỉ Source có):**
  - Cột Trái: Hiện nội dung DDL.
  - Cột Phải: Hiện placeholder trống với label rõ ràng: `[ NEW DDL HERE ]`.
- **Trường hợp Deleted DDL (Chỉ Destination có):**
  - Cột Trái: Hiện placeholder trống với label: `[ DELETED DDL CASE ]`.
  - Cột Phải: Hiện nội dung DDL cũ đang tồn tại ở đích.

> **Note:** Độ cao (height) của Placeholder phải khớp chính xác với độ cao của khối code đối diện để đảm bảo tính thẳng hàng khi cuộn.

---

## 4. TÍNH NĂNG GIỮ LẠI (MINIMUM VIABLE FEATURES)

- **Settings:** Cấu hình Connection, Env Color, Font size.
- **CompareView Control:** - Nút `Generate Script` (để sync thủ công).
  - Nút `Refresh` để re-scan cấu trúc.

---

## 5. HIỆU ỨNG THỊ GIÁC (VISUALS)

- **Background:** Sạch sẽ, tương phản cao (Dark mode hoặc White tinh khiết).
- **Highlighting:** - Màu xanh lá nhạt cho dòng mới (New).
  - Màu đỏ nhạt cho dòng bị xóa (Deleted).
  - Màu vàng nhạt cho dòng bị thay đổi (Modified).
