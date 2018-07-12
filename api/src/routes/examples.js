const _ = require('lodash/fp')
const express = require('express')
const router = express.Router()

router.get('/:owner/:repo/:module/:function', (req, res) => {

  cors(async (req, res) => {
    const params = req.query

    if (!params.module) {
      res
        .status(400)
        .send(`Please specify the 'module' you want to search in`)
      return
    }

    if (!params.function) {
      res
        .status(400)
        .send(`Please specify the 'function' you want to search for`)
      return
    }

    const invalidKeys = _.without(['module', 'function', 'version'], _.keys(params))

    if (invalidKeys.length > 0) {
      res
        .status(400)
        .send(`These parameters are not allowed: ${invalidKeys.join(',')}`)
      return
    }

    const module = params.module
    const func = params.function
    const version = params.version

    return send(res, 200, {module, func, version})
  })

})

module.exports = router
