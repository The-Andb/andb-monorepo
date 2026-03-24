const { CoreBridge } = require('./andb-core/dist/index.js');
const { DesktopStorageStrategy } = require('./andb-desktop/electron/storage/strategy/desktop-storage.strategy.js');
const path = require('path');

async function test() {
  try {
    const dataPath = path.join(process.cwd(), 'TheAndbData');
    const sqlitePath = path.join(dataPath, 'the_andb.db');
    
    console.log("Init core bridge...");
    await CoreBridge.init(dataPath, sqlitePath, new DesktopStorageStrategy(), dataPath);
    
    console.log("Execute compare...");
    await CoreBridge.execute('compare', {
      srcEnv: 'DEV',
      destEnv: 'UAT',
      type: 'tables',
      name: 'admin_email_recipient'  // from the user's screenshot
    });
    
    console.log("Done execution.");
  } catch (err) {
    console.error(err);
  }
}
test();
