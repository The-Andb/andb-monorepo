const { CoreBridge } = require('./andb-core/dist/core-bridge');

async function run() {
  await CoreBridge.init();
  
  const payload = {
    connection: {
      type: 'mysql',
      host: '10.255.255.255',
      port: 3306,
      username: 'root',
      password: '',
      database: 'test'
    }
  };

  console.log("Testing timeout connection...");
  const start = Date.now();
  try {
    const result = await CoreBridge.execute('test-connection', payload);
    console.log("Result:", result, "Time:", Date.now() - start);
  } catch (e) {
    console.error("Error:", e, "Time:", Date.now() - start);
  }
  process.exit(0);
}

run();
