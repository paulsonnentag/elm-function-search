const fs = require('fs-extra')
const _ = require('lodash/fp')

const findAllRepos = require('./find-all-repos')

module.exports = async () => {
  return _.take((await findAllRepos({query: 'language:elm', limit: 10})), 10)
}
