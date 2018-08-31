const knex = require('knex')(require('./knexfile')[process.env.NODE_ENV || 'development']);
const dbMigration = knex.migrate.latest()

const util = require('util')
const exec = util.promisify(require('child_process').exec)


// IMPORT REPO

const importRepo = require('./tasks/import-repo')

async function importRepoHandler (event, context) {
  await dbMigration

  if (event.Records.length > 1) {
    context.fail('only batch size of 1 permitted')
    return
  }

  const repo = JSON.parse(event.Records[0].messageBody)

  await importRepo(knex, repo)
    .then(() => context.succeed('done'))
    .catch((err) => context.fail(err))
}

// FETCH REPOS

const fetchRepos = require('./tasks/fetch-repos')

async function fetchReposHandler (event, context) {
  console.log('start fetch repos')

  await fetchRepos()
    .then(() => context.succeed('done'))
    .catch((err) => context.fail(err))

  console.log('done fetch')
}

module.exports = {
  importRepo: importRepoHandler,
  fetchRepos: fetchReposHandler,
}