const { spawnSync } = require('child_process');
const { existsSync } = require('fs');
const { join } = require('path');

const repos = {
  'andb-core': 'https://github.com/The-Andb/andb-core.git',
  'andb-cli': 'https://github.com/The-Andb/andb-cli.git',
  'andb-desktop': 'https://github.com/The-Andb/andb-desktop.git',
  'andb-mcp': 'https://github.com/The-Andb/andb-mcp.git',
  'andb-www': 'https://github.com/The-Andb/andb-www.git',
  'andb-test': 'https://github.com/The-Andb/andb-test.git',
  'org': 'https://github.com/The-Andb/org.git'
};

const command = process.argv[2];

function run(cmd, args, cwd) {
  cwd = cwd || process.cwd();
  console.log('\n\x1b[1m> ' + cmd + ' ' + args.join(' ') + ' (in ' + cwd + ')\x1b[0m');
  const result = spawnSync(cmd, args, { cwd: cwd, stdio: 'inherit', shell: false });
  if (result.status !== 0) {
    console.error('\x1b[31mCommand failed with exit code ' + result.status + '\x1b[0m');
    return false;
  }
  return true;
}

function handleClone() {
  for (const dir in repos) {
    const url = repos[dir];
    if (existsSync(dir)) {
      console.log('\x1b[34m[SKIPPED] ' + dir + ' already exists.\x1b[0m');
    } else {
      console.log('\x1b[32m[CLONING] ' + dir + ' from ' + url + '...\x1b[0m');
      run('git', ['clone', url, dir]);
    }
  }
}

function handlePull() {
  // Pull root repo first
  console.log('\x1b[34m[PULL ROOT]...\x1b[0m');
  run('git', ['pull']);

  for (const dir in repos) {
    if (existsSync(dir)) {
      console.log('\x1b[32m[PULL] ' + dir + '...\x1b[0m');
      run('git', ['pull'], join(process.cwd(), dir));
    } else {
      console.log('\x1b[33m[SKIPPED] ' + dir + ' does not exist. Run "repo:clone" first.\x1b[0m');
    }
  }
}

function handlePush() {
  // Push root repo first
  console.log('\x1b[34m[PUSH ROOT]...\x1b[0m');
  run('git', ['push']);

  for (const dir in repos) {
    if (existsSync(dir)) {
      console.log('\x1b[32m[PUSH] ' + dir + '...\x1b[0m');
      run('git', ['push'], join(process.cwd(), dir));
    } else {
      console.log('\x1b[33m[SKIPPED] ' + dir + ' does not exist.\x1b[0m');
    }
  }
}

function handleStatus() {
  for (const dir in repos) {
    if (existsSync(dir)) {
      console.log('\x1b[34m[STATUS] ' + dir + '\x1b[0m');
      run('git', ['status', '-s'], join(process.cwd(), dir));
    } else {
      console.log('\x1b[33m[SKIPPED] ' + dir + ' does not exist.\x1b[0m');
    }
  }
}

function handleCheckout() {
  const args = process.argv.slice(3);
  let branch = '';
  let createNew = false;

  if (args[0] === '-b') {
    createNew = true;
    branch = args[1];
  } else {
    branch = args[0];
  }

  if (!branch) {
    console.error('\x1b[31mError: Please specify a branch name.\x1b[0m');
    console.log('Usage: node scripts/repo-manage.js checkout [-b] <branch-name>');
    process.exit(1);
  }

  const gitArgs = createNew ? ['checkout', '-b', branch] : ['checkout', branch];

  // Checkout root repo first
  console.log('\x1b[34m[CHECKOUT ROOT] to ' + branch + (createNew ? ' (NEW)' : '') + '...\x1b[0m');
  run('git', gitArgs);

  // Checkout sub-repos
  for (const dir in repos) {
    if (existsSync(dir)) {
      console.log('\x1b[32m[CHECKOUT] ' + dir + ' to ' + branch + (createNew ? ' (NEW)' : '') + '...\x1b[0m');
      run('git', gitArgs, join(process.cwd(), dir));
    } else {
      console.log('\x1b[33m[SKIPPED] ' + dir + ' does not exist.\x1b[0m');
    }
  }
}

function handleFixPerms() {
  console.log('\x1b[32m[FIXING] Adding all subdirectories to git safe.directory...\x1b[0m');
  run('git', ['config', '--global', '--add', 'safe.directory', '*']);
}

switch (command) {
  case 'clone':
    handleClone();
    break;
  case 'pull':
    handlePull();
    break;
  case 'status':
    handleStatus();
    break;
  case 'fix-perms':
    handleFixPerms();
    break;
  case 'checkout':
    handleCheckout();
    break;
  case 'push':
    handlePush();
    break;
  default:
    console.error('Usage: node scripts/repo-manage.js [clone|pull|push|status|fix-perms|checkout]');
    process.exit(1);
}
