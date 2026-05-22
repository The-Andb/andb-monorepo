const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

// Path found from execution logs
const DB_PATH = '/Volumes/FlexibleWorkplace/side-pr/TheAndbData/andb-storage.db';

if (!fs.existsSync(DB_PATH)) {
  console.error(`❌ Database file not found at: ${DB_PATH}`);
  process.exit(1);
}

try {
  console.log(`🔌 Connecting to SQLite DB at: ${DB_PATH}`);
  const db = new Database(DB_PATH);

  // Explicitly clear history cache data, preserve user configuration (projects, envs, settings)
  const tablesToTruncate = [
    'ddl_exports',
    'comparisons',
    'migration_histories',
    'ddl_snapshots'
  ];

  console.log('🧹 Starting maintenance truncate...');
  
  for (const table of tablesToTruncate) {
    try {
      // Check if table exists
      const exists = db.prepare(`SELECT name FROM sqlite_master WHERE type='table' AND name='${table}';`).get();
      if (exists) {
        const countBefore = db.prepare(`SELECT COUNT(*) as count FROM ${table}`).get().count;
        db.prepare(`DELETE FROM ${table}`).run();
        console.log(`✅ Cleared ${countBefore} rows from ${table}`);
      }
    } catch (e) {
      console.warn(`⚠️ Skipping ${table}: ${e.message}`);
    }
  }

  // Optimize vacuum
  console.log('🔋 Compacting database (VACUUM)...');
  db.prepare('VACUUM').run();

  console.log('🎉 Database maintenance completed successfully! Everything is sparkling clean.');
  db.close();
} catch (error) {
  console.error('❌ CRITICAL ERROR:', error.message);
  if (error.message.includes('busy') || error.message.includes('locked')) {
    console.error('💡 TIP: Make sure to CLOSE the desktop app before running this command!');
  }
}
