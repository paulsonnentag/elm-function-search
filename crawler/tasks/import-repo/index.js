const fs = require('fs-extra')
const _ = require('lodash/fp')
const cloneRepo = require('./clone-repo')
const resolveDependencies = require('./resolve-dependencies')
const parseReferences = require('./parse-references')
const storeInDb = require('./store-in-db')
const cleanupRepo = require('./cleanup-repo')

module.exports = async (knex, repo) => {
  const repoName = `${repo.owner}/${repo.name}`
  const { packages, commitHash } = await cloneRepo(repoName)
  const references = _.flatten(await Promise.all(_.map(parseReferencesOfElmPackage, packages)))

  await Promise.all([
    storeInDb(knex, {repo, references, commitHash}),
    cleanupRepo(repoName)
  ])
}

async function parseReferencesOfElmPackage ({elmPackageFile, files}) {
  const elmPackage = await fs.readJson(elmPackageFile)
  const modules = await resolveDependencies(elmPackage.dependencies)

  return await Promise.all(_.map(async filePath => {
    const result = await (parseReferences(modules, filePath)
      .then((references) => ({type: 'success', data: {references}}))
      .catch((errors) => {
        console.log('failed to parse file', filePath, errors)

        return {type: 'error', data: {errors}}
      }))

    return {
      file: filePath,
      result
    }
  }, files))
}
