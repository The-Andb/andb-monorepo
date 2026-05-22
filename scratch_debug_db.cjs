const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

const dbPath = path.join(__dirname, 'andb-storage.db');
console.log('Opening database at:', dbPath);

if (!fs.existsSync(dbPath)) {
  console.error('Database file does not exist!');
  process.exit(1);
}

const db = new Database(dbPath);

console.log('\n--- Projects ---');
const projects = db.prepare('SELECT * FROM projects').all();
console.log(projects);

console.log('\n--- Project Settings ---');
const settings = db.prepare('SELECT * FROM project_settings').all();
console.log(settings);

console.log('\n--- DDL Exports (last 5) ---');
const ddlExports = db.prepare('SELECT environment, database_name, export_type, export_name, database_type, file_path FROM ddl_exports ORDER BY exported_at DESC LIMIT 5').all();
console.log(ddlExports);

for (const exp of ddlExports) {
  if (exp.file_path) {
    console.log(`Checking physical file for ${exp.export_name}:`);
    const possiblePaths = [
      path.join(__dirname, exp.file_path),
      path.join(__dirname, 'projects', 'theandb', exp.file_path),
      path.join(__dirname, 'projects', 'docker_preview', exp.file_path),
      exp.file_path
    ];
    for (const p of possiblePaths) {
      console.log(`  - ${p}: ${fs.existsSync(p) ? '✅ EXISTS' : '❌ NOT FOUND'}`);
    }
  }
}
