# Prompt / Spec cho Implementer — Secure Configuration Assistant (The Andb)

## 🎯 Mục tiêu

Xây dựng luồng **Secure Configuration Assistant** để thiết lập user `the_andb` với quyền hạn chế theo nguyên tắc **Least Privilege**, đảm bảo:

- **An toàn** cho DB của khách hàng.
- **Minh bạch** về quyền hạn.
- **UX rõ ràng** giữa Automatic và Manual (DBA Mode).
- **SQL script phải động** theo toggle quyền của user.

---

## ✅ Luồng tổng thể (4 steps)

### STEP 1 — Select Setup Mode (Bắt buộc chọn)

Màn hình gồm 2 lựa chọn ngang nhau:

#### Option A — Automatic Setup (Default được highlight)

- **Description**: "We’ll handle user creation and permission granting with precision. Recommended for most users."
- 👉 **Behavior**: Nếu user chọn Automatic, thì **BƯỚC SAU MỚI HIỆN FORM NHẬP ADMIN CREDENTIALS**.

#### Option B — Manual Setup (DBA Mode)

- **Description**: "You maintain full control. We ensure the script is generated for you to review and execute."
- 👉 **Behavior**: Nếu user chọn Manual, thì:
  - **KHÔNG** hiện form nhập admin credentials.
  - Chỉ cần nhập: **Host**, **Port**, **Database** (optional, nếu có thể detect thì tốt).
  - Sau đó chuyển thẳng sang màn hình phân quyền (Step 2).

---

### STEP 2 — Access Capabilities (Core Screen)

Màn hình này luôn giống nhau cho cả Auto & Manual, chỉ khác behavior phía sau.

#### UI Components

**Header**: ACCESS CAPABILITIES

**Danh sách toggle (switch):**

1.  **Read-Only Core (MANDATORY)** — luôn bật, không tắt được.
    - _Description_: "Allows The Andb to understand your database structure without modifying data."

2.  **Schema Change Support (ALTER TABLE)**
    - _Description_: "Allow The Andb to suggest and apply table modifications (ALTER TABLE) for synchronization."

3.  **View Management**
    - _Description_: "Allow updating view definitions when differences are detected across environments."

4.  **Routine Management (Functions & Procedures)**
    - _Description_: "Allow updating Stored Procedures and Functions to ensure consistent business logic."

#### 🔁 Behavior theo mode:

- 👉 **Nếu MANUAL MODE**:
  - Khi user bật/tắt toggle → SQL script phải cập nhật realtime ở Step 3.
  - Không cần admin password ở bất kỳ bước nào.
- 👉 **Nếu AUTOMATIC MODE**:
  - Sau khi bấm Next, chuyển sang Step nhập admin credentials (như màn hình user gửi).

---

### STEP 2B — Admin Credentials (CHỈ AUTO MODE)

#### UI Form:

- Connection Name
- Host
- Port
- Database
- Username (Admin)
- Password (Admin)

#### Thông báo bảo mật (Bắt buộc):

> "Admin privileges are used only once to prepare the environment. Your password is processed in volatile memory and discarded immediately after setup. The Andb never stores your sensitive admin credentials."

---

### STEP 3 — Generated SQL Script (CHỈ MANUAL MODE)

**Tiêu đề**: Generated SQL Script

#### Rules:

1.  SQL phải tự động thay đổi theo toggle quyền (từ Step 2).
2.  Phải dùng user cố định: `the_andb`.
3.  Có nút **Copy**.
4.  Có chú thích rõ ràng.

#### Ví dụ base script (tối thiểu):

```sql
-- Base: Create user and basic metadata access
CREATE USER 'the_andb'@'%' IDENTIFIED BY 'YourStrongPassword123!';

-- READ Permissions (Required)
GRANT SELECT, SHOW VIEW, SHOW ROUTINE ON *.* TO 'the_andb'@'%';
GRANT SHOW CREATE TABLE ON `{{database_name}}`.* TO 'the_andb'@'%';

-- Nếu bật Schema Change Support (ALTER TABLE):
GRANT ALTER ON `{{database_name}}`.* TO 'the_andb'@'%';

-- Nếu bật View Management:
GRANT ALTER VIEW ON `{{database_name}}`.* TO 'the_andb'@'%';

-- Nếu bật Routine Management:
GRANT ALTER ROUTINE ON `{{database_name}}`.* TO 'the_andb'@'%';

-- Kết thúc luôn bằng:
FLUSH PRIVILEGES;
```

**Text dưới script**:
"Please execute this script on your database server as an administrator. Once done, verify the connection below."

---

### STEP 3B — Ready to Configure (CHỈ AUTO MODE)

**Màn hình**: "We will create the user `the_andb` and apply the selected permissions."

**Nút lớn**: `Start Configuration`

**Backend process**:

1.  Create user.
2.  Grant quyền theo toggle.
3.  Flush privileges.

---

### STEP 4 — Verification Suite (BẮT BUỘC CHO CẢ HAI MODE)

**Nút**: `Run Checks`

#### Checklist cần chạy (Backend):

1.  **Connection Establishment**
    - Thử connect bằng `the_andb`.
    - Nếu fail → báo lỗi chi tiết.

2.  **Schema Reading**
    - Chạy:
      ```sql
      SHOW CREATE TABLE some_table;
      SHOW FULL TABLES WHERE TABLE_TYPE='VIEW';
      ```
    - Nếu thiếu quyền → báo rõ.

3.  **Permission Boundaries**
    - Phải đảm bảo **KHÔNG** được phép:
      - `DROP TABLE`
      - `DELETE FROM` (ngoài phạm vi cho phép)
      - `TRUNCATE TABLE`
    - Nếu có hành vi bị chặn → đánh dấu **PASS** (đây là test ngược).

#### Kết thúc:

**Nút cuối**: `FINISH & CONNECT`

**Hành động**:

1.  Lưu connection.
2.  Chuyển vào màn hình chính của The Andb.

---

## 🎯 Điểm quan trọng Implementer phải tuân thủ

- **Manual = Zero risk**: The Andb **KHÔNG** tự chạy bất kỳ lệnh nào lên DB.
- **Automatic = One-time privilege**: Admin password chỉ dùng 1 lần, không lưu.
- **Transparency**: Tất cả SQL phải minh bạch, User luôn có thể xem được.
