# Kế hoạch triển khai: Module Database Pulse (Live Monitoring)

Chúng tôi đã đọc bản thiết kế của bạn và tiến hành nghiên cứu codebase của **The Andb**. Dưới đây là phần **phản biện chuyên môn về mặt kỹ thuật** và **kế hoạch triển khai chi tiết từng file** để hiện thực hóa tính năng này một cách an toàn và chuyên nghiệp nhất.

---

## 1. Phản biện & Đóng góp kỹ thuật (Technical Feedback & Critique)

### 1.1. Lỗi cú pháp SQL trong query Lock Tree (Quan trọng)

Trong câu query Lock Tree ở Phase 1.2:

```sql
FROM performance_schema.data_lock_waits waiting_w
JOIN performance_schema.threads waiting_t ON waiting_w.REQUESTING_THREAD_ID = waiting_t.THREAD_ID
JOIN performance_schema.data_lock_waits blocking_w ON waiting_w.ENGINE_LOCK_ID = blocking_w.ENGINE_LOCK_ID
JOIN performance_schema.threads blocking_t ON blocking_w.BLOCKING_THREAD_ID = blocking_t.THREAD_ID;
```

- **Lỗi 1**: Bảng `performance_schema.data_lock_waits` không hề có cột `ENGINE_LOCK_ID`. Cột thực tế là `REQUESTING_ENGINE_LOCK_ID` và `BLOCKING_ENGINE_LOCK_ID`.
- **Lỗi 2**: Bảng `data_lock_waits` mô tả quan hệ đợi lock giữa hai thread (requester và blocker) ngay trên một hàng. Do đó, **không cần self-join** chính bảng này. Việc self-join như trên sẽ cho kết quả sai lệch và gây quá tải DB.
- **Query sửa đổi chuẩn xác**:
  ```sql
  SELECT /*+ MAX_EXECUTION_TIME(1000) */
      waiting_t.PROCESSLIST_ID AS waiting_thread_id,
      LEFT(waiting_t.PROCESSLIST_INFO, 255) AS waiting_query,
      blocking_t.PROCESSLIST_ID AS blocking_thread_id,
      LEFT(blocking_t.PROCESSLIST_INFO, 255) AS blocking_query,
      blocking_t.PROCESSLIST_STATE AS blocking_state
  FROM performance_schema.data_lock_waits w
  JOIN performance_schema.threads waiting_t ON w.REQUESTING_THREAD_ID = waiting_t.THREAD_ID
  JOIN performance_schema.threads blocking_t ON w.BLOCKING_THREAD_ID = blocking_t.THREAD_ID;
  ```

### 1.2. Tính tương thích ngược (MySQL 5.7 vs 8.0 & MariaDB)

- Bảng `performance_schema.data_lock_waits` chỉ xuất hiện từ **MySQL 8.0.3+**. Nếu khách hàng dùng MySQL 5.7 hoặc tắt `performance_schema`, query Pulse và Snapshot sẽ crash.
- **Giải pháp**: Ở tầng Core của Driver, chúng ta sẽ bắt ngoại lệ (try-catch). Nếu bảng trên không tồn tại, ta sẽ tự động fallback sang bảng `information_schema.innodb_lock_waits` (cho MySQL 5.7) hoặc trả về `lockWaits = 0` một cách an toàn thay vì làm treo ứng dụng.
- Optimizer hint `/*+ MAX_EXECUTION_TIME(1000) */` không được hỗ trợ bởi MariaDB. Ta cần xử lý fallback bỏ hint nếu dialect không khớp.

### 1.3. Vấn đề kết nối định kỳ qua SSH Tunnel (Port Exhaustion)

- Cơ chế Driver hiện tại của The Andb hoạt động theo triết lý **On-Demand**: Mỗi lần gọi query sẽ mở kết nối mới (`driver.connect()`) và ngắt kết nối ngay sau đó (`driver.disconnect()`).
- Nếu Pulse Check chạy mỗi **3 giây/lần**, việc liên tục tạo và đóng kết nối TCP qua SSH Tunnel sẽ làm quá tải hệ thống SSH và cạn kiệt port của máy local (Port Exhaustion).
- **Giải pháp**: Chúng ta phải triển khai cơ chế **Persistent Connection** riêng cho Monitor. Khi User mở tab "Database Pulse", Electron main process sẽ tạo một connection instance và giữ nó sống (keep-alive) cho đến khi user đổi tab hoặc đóng app.

### 1.4. Đính chính kiến trúc Backend của Desktop App

- Bản kế hoạch giả định NestJS/REST API. Thực tế, The Andb Desktop app là ứng dụng Electron chạy ngoại tuyến. Việc giao tiếp giữa UI (Vue 3) và Core Engine diễn ra thông qua **Electron IPC Bridge** (`core-worker.cjs` trong background).
- Vì vậy, thay vì xây dựng REST endpoints, chúng ta sẽ xây dựng các **IPC Channels** và đăng ký các operation mới vào `OrchestrationService` của `@the-andb/core`.

### 1.5. Đóng góp để "Tìm ra điểm nghẽn của DB ngay lập tức" (Critical Additions)

Để Database Pulse thực sự giúp tìm ra điểm nghẽn **ngay lập tức**, kế hoạch ban đầu cần được nâng cấp các điểm sau:

1. **Bắt được Idle Transactions (Thread đang Sleep nhưng giữ Lock)**:
   - **Vấn đề**: Bản kế hoạch ban đầu lọc bỏ các thread `Sleep` ở câu query processlist (`WHERE COMMAND != 'Sleep'`). Trong thực tế, các transaction mở bị bỏ quên (Idle Transactions) ở trạng thái `Sleep` nhưng vẫn giữ lock độc quyền mới là **nguyên nhân phổ biến nhất** gây nghẽn.
   - **Giải pháp**: Không lọc bỏ `Sleep` một cách mù quáng. Chúng ta sẽ giữ lại các thread đang `Sleep` nếu chúng nằm trong bảng `information_schema.innodb_trx` (đang có transaction hoạt động) hoặc là root blocker trong Lock Tree, kèm theo badge cảnh báo nổi bật: `🔴 IDLE TRANSACTION`.
2. **Tích hợp tính năng "Quick EXPLAIN" và "EXPLAIN ANALYZE"**:
   - **Ý tưởng**: Khi phát hiện một câu query đang chạy rất chậm, user cần biết kế hoạch thực thi (EXPLAIN) hoặc thời gian chạy thực tế ở từng bước (EXPLAIN ANALYZE).
   - **Giải pháp**: Thêm 2 tùy chọn **EXPLAIN** và **EXPLAIN ANALYZE** bên cạnh mỗi active query trong bảng Processlist.
   - **⚠️ CẢNH BÁO BẢO MẬT & HIỆU NĂNG**:
     - Khác với `EXPLAIN` (chỉ giả lập), `EXPLAIN ANALYZE` sẽ **thực sự chạy** câu query đó để đo thời gian thực tế. Nếu DB đang bị quá tải hoặc câu query quá nặng, việc chạy lại lần nữa có thể làm nghiêm trọng thêm điểm nghẽn.
     - **Biện pháp an toàn**:
       1. Chỉ cho phép chạy `EXPLAIN ANALYZE` đối với câu lệnh `SELECT` (kiểm tra Regex ở Frontend để chặn `UPDATE/DELETE`).
       2. Hiển thị hộp thoại xác nhận (Confirmation Dialog) cảnh báo hiệu năng trước khi thực thi.
       3. Tự động kiểm tra phiên bản: `EXPLAIN ANALYZE` chỉ khả dụng trên **MySQL 8.0.18+**. Nếu phiên bản cũ hơn (MySQL 5.7), nút này sẽ bị mờ đi (disabled) kèm tooltip giải thích.

3. **Nút "AI Diagnose" (DBA thông minh 1-Click)**:
   - Tận dụng module AI (Gemini) đã tích hợp sẵn trong The Andb để phân tích nhanh snapshot. Chỉ cần 1 click, AI sẽ đọc dữ liệu Lock Tree + Processlist và đưa ra chẩn đoán bằng 3 dòng ngắn gọn: _Điểm nghẽn nằm ở đâu, câu lệnh nào đang gây hại, và hành động cụ thể cần làm (ví dụ: tạo Index cụ thể nào)._
4. **Phân loại & Cảnh báo Trạng thái Nặng (Heavy States)**:
   - Highlight nổi bật bằng màu sắc (Đỏ/Cam) các thread đang ở trạng thái tốn nhiều CPU/Disk IO như: `Creating sort index`, `Copying to tmp table`, `Searching rows`, `Locked`.

---

## 2. Kế hoạch triển khai chi tiết

### 2.1. Tầng Core (`@the-andb/core`)

#### [MODIFY] [driver.interface.ts](file:///Volumes/FlexibleWorkplace/The-Andb/andb-core/src/common/interfaces/driver.interface.ts)

Bổ sung các phương thức mới vào interface `IMonitoringService`:

```typescript
export interface IMonitoringService {
  // ... các phương thức cũ
  getPulseStats(): Promise<{ threadsRunning: number; lockWaits: number }>;
  getDeepSnapshot(): Promise<{ lockTree: any[]; processList: any[] }>;
  killThread(threadId: number): Promise<void>;
}
```

#### [MODIFY] [mysql.monitoring.ts](file:///Volumes/FlexibleWorkplace/The-Andb/andb-core/src/modules/driver/mysql/mysql.monitoring.ts)

Implement 3 hàm trên cho MySQL với cơ chế xử lý lỗi/fallback:

- `getPulseStats`: Query `Threads_running` và số lượng locks. Bắt lỗi nếu performance_schema không được bật để fallback về `0` locks.
- `getDeepSnapshot`: Query Lock Tree (đã sửa cú pháp join) và active process list.
- `killThread`: Chạy câu lệnh `KILL <threadId>`.

#### [MODIFY] [orchestration.service.ts](file:///Volumes/FlexibleWorkplace/The-Andb/andb-core/src/modules/orchestration/orchestration.service.ts)

Thêm các case handler mới:

- `case 'monitor-pulse': return await this.schemaOrchestrator.getPulseStats(payload);`
- `case 'monitor-snapshot': return await this.schemaOrchestrator.getDeepSnapshot(payload);`
- `case 'monitor-kill': return await this.schemaOrchestrator.killThread(payload);`

#### [MODIFY] [schema-orchestrator.service.ts](file:///Volumes/FlexibleWorkplace/The-Andb/andb-core/src/modules/orchestration/schema-orchestrator.service.ts)

Bổ sung các hàm tương ứng để lấy connection driver và gọi qua service giám sát (`IMonitoringService`).

---

### 2.2. Tầng Main Process (`andb-desktop/electron`)

#### [MODIFY] [preload.ts](file:///Volumes/FlexibleWorkplace/The-Andb/andb-desktop/electron/preload.ts)

Expose các hàm IPC mới cho phía UI:

```typescript
  monitorPulse: (connection: any) => ipcRenderer.invoke('andb-monitor-pulse', { connection }),
  monitorSnapshot: (connection: any) => ipcRenderer.invoke('andb-monitor-snapshot', { connection }),
  monitorKill: (connection: any, threadId: number) => ipcRenderer.invoke('andb-monitor-kill', { connection, threadId }),
```

#### [MODIFY] [ipc/andb.ts](file:///Volumes/FlexibleWorkplace/The-Andb/andb-desktop/electron/ipc/andb.ts)

Đăng ký các IPC Main handlers và liên kết qua `AndbBuilder` để gọi xuống core-worker:

- `handleAndbMonitorPulse`
- `handleAndbMonitorSnapshot`
- `handleAndbMonitorKill`

---

### 2.3. Tầng Giao diện UI (`andb-desktop/src`)

#### [NEW] [DatabasePulse.vue](file:///Volumes/FlexibleWorkplace/The-Andb/andb-desktop/src/components/compare/DatabasePulse.vue)

Tạo component hiển thị Pulse Monitor trực quan:

- **Status Indicator**: Banner cảnh báo đổi màu (Xanh lá - Bình thường, Vàng - Cảnh báo, Đỏ - Nguy hiểm/Critical).
- **Lock Tree**: Vẽ sơ đồ hình cây hiển thị thread nào đang block các thread con khác, kèm nút "Kill" cạnh root thread.
- **Process List**: Bảng hiển thị thông tin chi tiết các thread đang chạy kèm công cụ tìm kiếm và lọc.

#### [NEW]

- Tạo mới table `Database Pulse`.
- Cài đặt live polling logic:
  - Cứ mỗi 3 giây gọi API `monitorPulse` của connection đích.
  - Sử dụng **Page Visibility API** để tự động dừng polling khi tab bị ẩn.
  - Cài đặt thời gian tự động dừng sau 5 phút không hoạt động (Auto-Stop) để tránh tiêu tốn tài nguyên DB.

---

## 3. Kế hoạch Xác minh & Kiểm thử (Verification Plan)

### 3.1. Kiểm thử tự động (Automated Tests)

Viết unit test cho `MysqlMonitoringService` để xác nhận các query chạy đúng cấu trúc dữ liệu trả về mong muốn.

### 3.2. Kiểm thử thực tế (Manual Simulation)

1. Sử dụng môi trường MySQL Docker để giả lập Lock lớn (chạy `SELECT ... FOR UPDATE` không commit).
2. Mở The Andb và truy cập tab "Database Pulse" để xác nhận cây Lock Tree chỉ ra đúng ID của thread chủ mưu.
3. Nhấp nút "Kill" để kiểm tra xem lock có được giải phóng ngay lập tức hay không.
