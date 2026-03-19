const { CoreBridge } = require('./andb-core/dist/core-bridge');

async function run() {
  await CoreBridge.init();
  
  const payload = {
    connection: {
      type: 'mysql',
      host: 'localhost',
      port: 3306,
      username: 'root',
      password: '',
      database: 'test'
    }
  };

  console.log("Testing connection...");
  try {
    const result = await CoreBridge.execute('test-connection', payload);
    console.log("Result:", result);
  } catch (e) {
    console.error("Error:", e);
  }
  process.exit(0);
}

run();
