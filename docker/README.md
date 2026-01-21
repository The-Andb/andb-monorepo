# 🐳 Docker Test Environment

4 MySQL containers simulating DEV, STAGE, UAT, PROD environments.

## 🚀 Quick Start

### 1. Start All Databases
```bash
docker-compose up -d
```

### 2. Check Status
```bash
docker-compose ps
```

### 3. Test Connections
```bash
# DEV
mysql -h 127.0.0.1 -P 3306 -u dev_user -pdev_pass dev_database

# STAGE
mysql -h 127.0.0.1 -P 3307 -u stage_user -pstage_pass stage_database

# UAT
mysql -h 127.0.0.1 -P 3308 -u uat_user -puat_pass uat_database

# PROD
mysql -h 127.0.0.1 -P 3309 -u prod_user -pprod_pass prod_database
```

### 4. Stop All
```bash
docker-compose down
```

### 5. Clean & Rebuild
```bash
docker-compose down -v  # Remove volumes
docker-compose up -d --build
```

---

## 📊 Environment Details

| Environment | Port | Database       | User       | Password   |
| ----------- | ---- | -------------- | ---------- | ---------- |
| **DEV**     | 3306 | dev_database   | dev_user   | dev_pass   |
| **STAGE**   | 3307 | stage_database | stage_user | stage_pass |
| **UAT**     | 3308 | uat_database   | uat_user   | uat_pass   |
| **PROD**    | 3309 | prod_database  | prod_user  | prod_pass  |

---

## 🧪 Test with andb-cli

### Export
```bash
andb export --tables DEV
andb export --procedures STAGE
andb export --functions UAT
```

### Compare
```bash
andb compare --tables DEV STAGE
andb compare --procedures STAGE UAT
```

### Migrate
```bash
andb migrate:new --from DEV --to STAGE
andb migrate:update --file migrations/20241027_001.sql
```

---

## 📝 Schema Setup ✅

**E-commerce System Schema with differences across environments:**

| Environment | Records (Users/Orders) | Tables | Objects (View/Proc/Func) | Indexes | Differences                          |
| ----------- | ---------------------- | ------ | ------------------------ | ------- | ------------------------------------ |
| **DEV**     | 50 / 200               | 10     | ✅ All (3)                | ✅ Full  | ✅ Complete Reference Implementation  |
| **STAGE**   | 25 / 100               | 10     | ✅ All (3)                | ⚠️ Missing 3 | ⚠️ Missing performance indexes        |
| **UAT**     | 10 / 40                | 10     | ❌ None                   | ⚠️ Missing 3 | ❌ Missing Views, Procs, Functions    |
| **PROD**    | 5 / 10                 | 10     | ❌ None                   | ⚠️ Missing 3 | ❌ Minimal data, missing logic objects|

**Perfect for testing andb-core compare & migrate!**

---

## 🔧 Useful Commands

### View Logs
```bash
docker-compose logs -f mysql-dev
docker-compose logs -f mysql-stage
```

### Execute SQL
```bash
docker exec -i andb-mysql-dev mysql -udev_user -pdev_pass dev_database < your-script.sql
```

### Backup
```bash
docker exec andb-mysql-dev mysqldump -udev_user -pdev_pass dev_database > backup.sql
```

### Restore
```bash
docker exec -i andb-mysql-stage mysql -ustage_user -pstage_pass stage_database < backup.sql
```

---

## 🗑️ Clean Up

### Remove all containers & volumes
```bash
docker-compose down -v
```

### Remove images
```bash
docker rmi mysql:8.0
```

---

**Ready for testing!** 🚀

