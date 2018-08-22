const knex = require('knex')(require('./knexfile')[process.env.NODE_ENV || 'development']);
const importRepo = require('./tasks/import-repo')

;(async () => {
  const t = Date.now()
  console.log('start')

  await importRepo(knex, {
    owner: 'rtfeldman',
    name: 'elm-css',
    stars: 100,
    license: 'MIT',
    lastUpdated: '2018-08-03 09:47:01'
  })

  console.log(`done: ${Date.now() - t}`)

  knex.destroy()
})()