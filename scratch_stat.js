const fs = require('fs');
const path = require('path');

const target = '/Volumes/FlexibleWorkplace/side-pr/TheAndbData/andb-storage.db';
try {
  console.log(`Checking stat for ${target}:`);
  const stats = fs.statSync(target);
  console.log(`Size: ${stats.size} bytes`);
  console.log(`Exists!`);
} catch (e) {
  console.error(`Failed stat:`, e.message);
}
