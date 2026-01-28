const DumpDriver = require('./core/src/drivers/mysql/DumpDriver');
const path = require('path');

const config = {
  dumpPath: path.resolve(__dirname, 'f1.sql')
};

const driver = new DumpDriver(config);

driver.connect().then(() => {
  console.log('Driver connected successfully');
  const introspection = driver.getIntrospectionService();
  introspection.listTables().then(tables => {
    console.log(`Found ${tables.length} tables`);
    if (tables.length > 0) {
      console.log('Sample tables:', tables.slice(0, 5));
    }
  });
}).catch(err => {
  console.error('Connection failed:', err);
});
