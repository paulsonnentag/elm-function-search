const express = require('express')
const router = express.Router()
const {session} = require('../db')

router.get('/', (req, res) => {
  const {package, module, symbol} = req.query

  if (!package) {
    res
      .status(400)
      .send(`Please specify the 'package' of the symbol`)
    return
  }

  if (!module) {
    res
      .status(400)
      .send(`Please specify the 'module' of the symbol`)
    return
  }

  if (!symbol) {
    res
      .status(400)
      .send(`Please specify the 'symbol'`)
    return
  }

  findExamples({ package, module, symbol })
    .then(examples => {
      console.log(examples)

      res.send(examples)
    })
})


async function findExamples ({ package, module, symbol}) {
  const {records} = await session.run(`
    MATCH
      (module:File)-[:DEFINES_SYMBOL]->(symbol:Symbol),
      (refRepo:Repo)-[:HAS_FILE]->(:File)-[ref:REFERENCES_SYMBOL]->(symbol)
    WHERE
      module.module = $package + '/' + $module AND
      symbol.name = $symbol
    RETURN DISTINCT
      refRepo.id AS repo, ref.url AS url
    LIMIT 100
  `,
    {package, module, symbol}
  )

  return records.map((row) => {
    return {
      repo: row.get('repo'),
      url: row.get('url'),
    }
  })
}

module.exports = router
