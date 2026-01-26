const fs = require('fs');
const path = require('path');

// Mock logger
global.logger = {
  info: console.log,
  warn: console.warn,
  error: console.error
};

const DumpDriver = require('./core/src/drivers/mysql/DumpDriver');

async function test() {
  const dumpPath = './ui/public/demo/demo-source.sql';
  console.log(`Testing DumpDriver with ${dumpPath}`);

  const driver = new DumpDriver({ host: dumpPath });

  try {
    await driver.connect();

    console.log('--- Parsing Results ---');
    console.log('Tables:', driver.data['tables'].size);
    if (driver.data['tables'].size > 0) {
      console.log('Table Keys:', [...driver.data['tables'].keys()]);
    }

    console.log('Views:', driver.data['views'].size);
    console.log('Procs:', driver.data['procedures'].size);

    // Check 'users' table specifically
    if (driver.data['tables'].has('users')) {
      console.log('Found users table!');
      console.log('Content:', driver.data['tables'].get('users').substring(0, 100) + '...');
    } else {
      console.error('FAILED: users table not found!');
    }
  } catch (e) {
    console.error('Error during test:', e);
  }
}

test();
