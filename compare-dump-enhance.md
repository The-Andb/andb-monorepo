# Enhancing SQL Dump Comparison: A DBA's Perspective

Với 30 năm kinh nghiệm quản trị cơ sở dữ liệu (DBA), mình khẳng định: **File SQL Dump không phải là một Live Connection.** Một file dump là một "snapshot" tĩnh, mang tính chất lưu trữ và tham chiếu, không phải là một thực thể vận hành (operational entity).

Do đó, kiến trúc của Andb cần phân biệt rạch ròi hai loại kết nối này để tránh các lỗi logic và bảo vệ dữ liệu.

## 1. Sự khác biệt cốt lõi (Live vs. Dump)

| Đặc tính              | Live Connection (Server)       | SQL Dump (File)                       |
| :-------------------- | :----------------------------- | :------------------------------------ |
| **Tính chất**         | Động, có trạng thái (Stateful) | Tĩnh, chỉ đọc (Read-only)             |
| **Khả năng thực thi** | Chấp nhận DDL (ALTER, CREATE)  | Không cho phép thay đổi nội dung file |
| **Bảo mật**           | Phân quyền qua User/Role       | Phân quyền file hệ thống              |
| **Backup**            | Cần cơ chế Snapshot/Full-dump  | Bản thân file chính là backup         |
| **Ngữ cảnh**          | Đa database, đa schema         | Thường là đơn database                |

## 2. Các quy tắc kiến trúc mới (Architectural Rules)

Dựa trên phân tích trên, hệ thống Andb sẽ áp dụng các giới hạn nghiêm ngặt sau cho các kết nối loại **Dump**:

### 🚫 Cấm Migrate (No Migration)

- Không được phép chạy lệnh `migrate` (thực thi SQL) vào một target là Dump.
- **Tại sao?** Vì Dump là file tĩnh. Việc "migrate" vào file dump bồ nên dùng tool text editor, không phải tool quản trị DB.

### 🚫 Cấm Backup/Restore (No Snapshots)

- Đối với Dump, logic "Lưu snapshot trước khi migrate" là vô nghĩa.
- Không cho phép tạo backup folder (`db/env/backup/...`) cho kết nối dump.

### 🚫 Cấm Checksum Live

- Các lệnh check checksum hoặc status server sẽ bị bỏ qua (Skip).

### ✅ Cho phép Introspection & Compare

- Dump đóng vai trò là **Source chuẩn** hoặc **Target tham chiếu**.
- Cho phép parse schema để so sánh với một DB thật hoặc một Dump khác.

## 3. Danh sách cập nhật Logic (To-do List)

### 🛠 AndbBuilder & UI

- [ ] **Validation Layer**: Chặn đứng nghiệp vụ `migrate` nếu `targetConn` là Dump.
- [ ] **Read-Only Flag**: Đánh dấu connection là read-only để UI disable các nút "Apply Migration", "Sync".
- [ ] **Path Enforcement**: Giữ nguyên cơ chế resolve path tuyệt đối đã làm.

### 🛠 Core Services

- [ ] **MigratorService**: Ném lỗi (Throw Error) nếu cố tình gọi migrate vào Dump driver.
- [ ] **ExporterService**: Skip các bước tạo thư mục backup nếu là Dump.

---

_"Một DBA giỏi không bao giờ cố gắng ALTER một file SQL Dump."_ - Old DBA.
