import { DesktopStorageStrategy } from './andb-desktop/electron/storage/strategy/desktop-storage.strategy';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';
import * as yaml from 'js-yaml';

async function run() {
  const userDataPath = path.join(os.homedir(), 'Library', 'Application Support', 'TheAndb_v3_dev');
  const dbConfigPath = path.join(userDataPath, 'db-config.yaml');
  let projectBaseDir = process.cwd();
  if (fs.existsSync(dbConfigPath)) {
    const content = fs.readFileSync(dbConfigPath, 'utf8');
    const match = content.match(/^projectBaseDir:\s*(.+)$/m);
    if (match && match[1]) {
       projectBaseDir = match[1].trim();
    }
  }

  const dbPath = path.join(userDataPath, 'andb-storage.db');
  console.log('Initializing strategy with base dir:', projectBaseDir);
  
  const strategy = new DesktopStorageStrategy();
  await strategy.initialize(dbPath, [], projectBaseDir);

  console.log('Mocking UAT Export...');
  await strategy.saveDdlExport({
    id: 'test-uat-1',
    environment: 'UAT',
    database_name: 'preflow_41',
    export_type: 'tables',
    export_name: 'mock_table',
    ddl_content: 'CREATE TABLE mock_table (id INT);',
    exported_at: new Date(),
    created_at: new Date(),
    updated_at: new Date()
  });

  console.log('Mocking Compare DEV -> UAT...');
  await strategy.saveComparison({
    id: 'test-compare-1',
    source_env: 'DEV',
    dest_env: 'UAT',
    database_name: 'preflow_41',
    type: 'TABLES',
    name: 'mock_table',
    status: 'MODIFIED',
    diff_html: '<p>diff</p>',
    alter_statements: '[{"up": "ALTER TABLE mock_table ADD COLUMN z INT;", "down": "ALTER TABLE mock_table DROP COLUMN z;", "shortInfo": "ADD_COLUMN_z"}]',
    compared_at: new Date(),
    created_at: new Date(),
    updated_at: new Date()
  });

  console.log('\\n--- Generating Tree of Base Dir ---');
  const { execSync } = require('child_process');
  console.log(execSync(`tree -d "${projectBaseDir}"`).toString());
  
  // Clean up mocks
  await strategy.queryRaw(`DELETE FROM ddl_exports WHERE id='test-uat-1'`);
  await strategy.queryRaw(`DELETE FROM comparisons WHERE id='test-compare-1'`);
  
  process.exit(0);
}

run().catch(console.error);
