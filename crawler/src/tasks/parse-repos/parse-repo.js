const fs = require('fs-extra')
const _ = require('lodash/fp')

const cloneRepo = require('./clone-repo')
const resolveDependencies = require('./resolve-dependencies')
const cleanupRepo = require('./cleanup-repo')
const parser = require('../../../../parser')

async function parseRepo (repoName) {
  const elmPackages = await cloneRepo(repoName)

  const result = _.flatten(await Promise.all(_.map(parseReferencesOfElmPackage, elmPackages)))

  await cleanupRepo(repoName)

  return result
}

async function parseReferencesOfElmPackage({ elmPackageFile, files}) {
  const elmPackage = await fs.readJson(elmPackageFile)
  const modules = await resolveDependencies(elmPackage.dependencies)


  return await Promise.all(_.map(async filePath => {
      const source = await fs.readFile(filePath, 'utf-8')

      const result = await (parser.parseReferences(modules, source)
        .then((references) => ({ type: 'success',  data: { references }}))
        .catch((errors) => ({ type: 'error', data: { errors }})))

      return {
        file: filePath,
        result
      }
  }, files))
}

module.exports = parseRepo