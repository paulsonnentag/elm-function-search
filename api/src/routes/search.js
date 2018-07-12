const _ = require('lodash/fp')
const {errorHandler} = require('../utils')
const express = require('express')
const router = express.Router()
const {session} = require('../db')

router.get('/symbols', async (req, res) => {
  if (req.query.name === undefined && req.query.package === undefined) {
    res
      .status(400)
      .send(`either 'name' or 'package' must be specified as a search parameter`)
    return
  }

  const {name, package} = req.query

  findMatchingSymbols({name, package})
    .then((symbols) => res.send(symbols))
    .catch(errorHandler(res))
})

router.get('/packages', async (req, res) => {
  if (req.query.name === undefined) {
    res
      .status(400)
      .send(`missing search parameter 'name'`)
    return
  }

  const {name} = req.query

  findMatchingPackages(name)
    .then((symbols) => res.send(symbols))
    .catch(errorHandler(req, res))
})

router.get('/all', async (req, res) => {
  if (req.query.name === undefined) {
    res
      .status(400)
      .send(`missing search parameter 'name'`)
    return
  }

  const {name} = req.query

  Promise.all([
    findMatchingSymbols({name}),
    findMatchingPackages(name)
  ])
    .then(([symbols, packages]) => res.send({symbols, packages}))
    .catch(errorHandler(req, res))
})

async function findMatchingPackages (name) {
  const {records} = await session.run(`
    MATCH (repo:Repo)
    WHERE repo.id CONTAINS $name
    RETURN repo.id AS name 
    ORDER BY repo.id ASC
    LIMIT 20
  `,
    {name}
  )

  return records.map((row) => ({
    name: row.get('name')
  }))
}

async function findMatchingSymbols ({name, package}) {
  const {records} = await session.run(`
    MATCH 
      (repo:Repo)-[:HAS_FILE]->(file:File)-[:DEFINES_SYMBOL]->(symbol:Symbol)      
    WHERE 
      ${name ? 'symbol.id CONTAINS $name' : ''}
      ${(package !== undefined && name !== undefined) ? 'AND' : ''}
      ${package ? 'AND repo.id = $package' : ''}
    RETURN symbol.name AS name, file.module as module
    ORDER BY symbol.name ASC
    LIMIT 20
  `,
    {name, package}
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
