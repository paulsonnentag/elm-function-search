const _ = require('lodash/fp')

const findAllRepos = require('./find-all-repos')
const emitRepo = require('./emit-repo')

module.exports = async () => {
  const repos =  _.take((await findAllRepos({query: 'language:elm', limit: 10})), 10)

  console.log("parse repos")

  return Promise.all(_.map(repo => {
    console.log('parse repo', repo)

    return emitRepo(repo)
  }, repos))
}
