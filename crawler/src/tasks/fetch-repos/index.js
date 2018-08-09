const fs = require('fs-extra')
const _ = require('lodash/fp')
const knex = require('knex')(require('../../knexfile')[process.env.NODE_ENV || 'development']);

const findAllRepos = require('./find-all-repos')
const upsertRepos = require('./upsert-repos')

;(async () => {
  const repos = await findAllRepos('language:elm')

  await upsertRepos(knex, repos)

  knex.destroy()
})()
