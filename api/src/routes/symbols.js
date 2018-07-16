const {errorHandler} = require('../utils')
const express = require('express')
const router = express.Router()
const {session} = require('../db')

router.get('/', async (req, res) => {
  const {query} = req.query

  if (query === undefined || query === '') {
    res
      .status(400)
      .send('query parameter can\'t be empty or undefined')
    return
  }

  findMatchingSymbols(query)
    .then((symbols) => res.send(symbols))
    .catch(errorHandler(res))
})


async function findMatchingSymbols (query) {
  const {records} = await session.run(`
    MATCH
      (repo:Repo)-[:HAS_FILE]->(file:File)-[:DEFINES_SYMBOL]->(symbol:Symbol)
    WHERE
      symbol.id CONTAINS $query
    RETURN
      symbol.name AS name, file.module as module
    ORDER BY
      symbol.name ASC
    LIMIT 30
  `,
    {query}
  )

  return records.map((row) => {
    const [owner, package, module] = row.get('module').split('/')

    return {
      module,
      name: row.get('name'),
      package: `${owner}/${package}`,
    }
  })
}

module.exports = router
