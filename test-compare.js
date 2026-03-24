const { fork } = require('child_process');
const path = require('path');
const os = require('os');

const cliPath = path.join(__dirname, 'andb-desktop', 'dist-electron', 'core-worker.cjs');
const userDataPath = path.join(os.homedir(), 'Library', 'Application Support', 'TheAndb_v3_dev');

const worker = fork(cliPath, ['--user-data-path', userDataPath], {
  stdio: ['pipe', 'pipe', 'pipe', 'ipc'],
  env: { ...process.env, ELECTRON_RUN_AS_NODE: '1' }
});

worker.on('message', (msg) => {
  console.log('[From Worker]', JSON.stringify(msg));
  if (msg.result && msg.result.success === false) {
    process.exit(1);
  } else if (msg.result || msg.error) {
     process.exit(0);
  }
});

worker.stdout.on('data', d => console.log(d.toString().trim()));
worker.stderr.on('data', d => console.error(d.toString().trim()));

setTimeout(() => {
  console.log('Sending COMPARE command...');
  worker.send({
    jsonrpc: '2.0',
    id: 1,
    method: 'execute',
    params: {
      operation: 'compareAll',
      payload: {
        srcEnv: 'DEV',
        destEnv: 'UAT',
        database: 'preflow_41'
      }
    }
  });
}, 2000);
