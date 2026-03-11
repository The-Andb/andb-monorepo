const SSMStorage = require('./configs/SSMStorage');
const {
  ENVIRONMENTS: { DEV, UAT, STAGE, PROD }
} = require('./configs/db');

require('dotenv').config();

(async () => {
  const {
    AWS_SSM_NAME_DEV = '',
    AWS_SSM_NAME_UAT = '',
    AWS_SSM_NAME_STAGE = '',
    AWS_SSM_NAME_PROD = '',
    AWS_REGION_DEV = '',
    AWS_REGION_UAT = '',
    AWS_REGION_STAGE = '',
    AWS_REGION_PROD = '',
  } = process.env;

  if (AWS_SSM_NAME_DEV.length) {
    await SSMStorage.init(AWS_SSM_NAME_DEV, AWS_REGION_DEV, DEV);
  }
  if (AWS_SSM_NAME_UAT.length) {
    await SSMStorage.init(AWS_SSM_NAME_UAT, AWS_REGION_UAT, UAT);
  }
  if (AWS_SSM_NAME_STAGE.length) {
    await SSMStorage.init(AWS_SSM_NAME_STAGE, AWS_REGION_STAGE, STAGE);
  }
  if (AWS_SSM_NAME_PROD.length) {
    await SSMStorage.init(AWS_SSM_NAME_PROD, AWS_REGION_PROD, PROD);
  }
  // const cli = require('./core/cli');
  const { commander } = require('andb-core');
  const {
    getDBDestination,
    getSourceEnv,
    getDestEnv,
    getDBName,
    replaceWithEnv,
    ENVIRONMENTS
  } = require('./configs/db');

  // Get base directory from environment or use current directory
  const andbCli = commander.build({
    getDBDestination,
    getSourceEnv,
    getDestEnv,
    getDBName,
    replaceWithEnv,
    ENVIRONMENTS,
    baseDir: process.env.BASE_DIR || process.cwd(),
    logName: "FloDB"
  });
  andbCli.parse(process.argv);
})();