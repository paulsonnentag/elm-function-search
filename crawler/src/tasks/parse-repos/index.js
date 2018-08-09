const knex = require('knex')(require('../../../knexfile')[process.env.NODE_ENV || 'development']);

const parseRepo = require('./parse-repo')

;(async () => {
    await knex('repos')
        .select('*')
        .whereRaw('last_crawled < last_updated OR last_crawled IS NULL')
        .then((repos) => {
            console.log(repos)
        })


    knex.destroy()
})()

