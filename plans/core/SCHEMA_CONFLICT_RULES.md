# ⚔️ The Andb Strict Schema Rules

Theo triết lý của The Andb, việc so sánh và đồng bộ Schema tuân thủ các quy tắc nghiêm ngặt sau để đảm bảo an toàn dữ liệu và tính minh bạch.

## 1. � Conflict (Property Mismatch)

**Định nghĩa duy nhất:** Conflict chỉ xảy ra khi cùng một tên cột (same column name) tồn tại ở cả hai bên nhưng có thuộc tính khác nhau.

- **Ví dụ**:
  - Source: `status VARCHAR(50)`
  - Target: `status INT`
  - -> **Conflict**: Khác Data Type.
  - Source: `email VARCHAR(255) NOT NULL`
  - Target: `email VARCHAR(255) NULL`
  - -> **Conflict**: Khác Nullability.
- **Hành động**: User buộc phải chọn một trong hai (Apply Source hoặc Keep Target). Đây là nơi UI Conflict Resolver tập trung xử lý.

## 2. 🟢 New Object/Column (Safe Addition)

- **Định nghĩa**: Tồn tại ở **Source** nhưng KHÔNG có ở **Target**.
- **Hành động**: Mặc định là **ADD** (Create Table / Add Column). Đây là hành động an toàn và mong muốn khi deploy tính năng mới.

## 3. ⚪ Deprecated/Missing (No-Touch Zone)

- **Định nghĩa**: KHÔNG có ở **Source** nhưng lại TỒN TẠI ở **Target**.
  - _Ví dụ_: Production (Target) có cột `legacy_id` cũ, nhưng trong Codebase (Source) đã xóa cột này khỏi model.
- **Hành động của The Andb**:
  - **Báo cáo**: Hiển thị là "Missing in Source" hoặc "Deprecated on Target".
  - **Thao tác**: **KHÔNG ĐƯỢC DROP**. The Andb mặc định sẽ **BỎ QUA** (Ignore) các cột này trong quá trình migrate/sync. Chúng tôi bảo vệ dữ liệu cũ, user phải tự tay drop bằng lệnh SQL thủ công nếu thực sự muốn.

## 4. 🚫 The "NO DROP" Policy (Critical)

**Quy tắc Bất di bất dịch**: The Andb **KHÔNG BAO GIỜ** tự động tạo lệnh `DROP` cho các cấu trúc chứa dữ liệu (Tables, Columns).

### ❌ Data Objects (Table, Column)

- **Action**: Tuyệt đối không xóa.
- **Lý do**: An toàn dữ liệu là ưu tiên số 1. Việc xóa bảng hay cột phải do con người thực hiện thủ công 100% qua một luồng riêng biệt, không được nằm trong luồng sync/migrate tự động.

### ⚠️ Logic Objects (View, Function, Procedure, Event)

- **Action**: Cho phép `DROP` (để tái tạo lại definition mới).
- **Điều kiện**:
  - Chỉ áp dụng khi nội dung logic thay đổi (Definition Mismatch).
  - Phải được **Review kỹ càng** bởi User trước khi execute.
  - Thường sử dụng pattern `DROP ... IF EXISTS` rồi `CREATE` lại để update logic.

---

## 🎨 Implication for UI (Visual Resolver)

1.  **Conflict Pane (Center Stage)**:
    - Chỉ hiện ra khi `Modified Object` có sự khác biệt về properties của các cột cùng tên.
    - Hiển thị Diff view so sánh thuộc tính (text diff).

2.  **Additions (Green)**:
    - Luôn được tính vào changelog để apply.

3.  **Deprecations (Gray/Warn)**:
    - Hiển thị trong UI để user biết là "DB có cột thừa".
    - Không generate lệnh `DROP COLUMN` trong script cuối cùng.
