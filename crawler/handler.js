const knex = require('knex')(require('./knexfile')[process.env.NODE_ENV || 'development']);
const dbMigration = knex.migrate.latest()

// IMPORT REPO

const importRepo = require('./tasks/import-repo')

async function importRepoHandler (event, context) {
  await dbMigration

  if (event.Records.length > 1) {
    context.fail('only batch size of 1 permitted')
    return
  }

  const repo = event.Records[0].messageAttributes

  await importRepo(knex, repo)
    .then(() => context.succeed('done'))
    .catch((err) => context.fail(err))
}

// FETCH REPOS

const fetchRepos = require('./tasks/fetch-repos')

async function fetchReposHandler (event, context) {

  context.succeed('done')

  callback(null, response)
}

module.exports = {
  importRepo: importRepoHandler,
  fetchRepos: fetchReposHandler,
}