const _ = require('lodash/fp')
const util = require('util')
const fs = require('fs-extra')
const path = require('path')
const glob = util.promisify(require('glob'))
const git = require('simple-git/promise')
const registry = require('../utils/package-registry')

const { TEMP_DIR } = require('../../config.json')

async function cloneRepo (name) {
  const repoDir = path.join(TEMP_DIR, name)

  await fetchRepo(repoDir, name)

  return getElmPackages (repoDir)
}

async function fetchRepo(repoDir, name) {
  const packages = await registry.getAllPackages()

  await fs.emptyDir(repoDir)
  const repo = git(repoDir)
  await repo.clone(`https://github.com/${name}.git`, '.')

  // if repos has been published to registry checkout latest published version
  const package = packages[name]
  if (package) {
    const latestVersion = package.versions[0]

    await repo.checkout(latestVersion)
  }
}

async function getElmPackages (repoDir) {
  // get folders which have elm-package.json
  const elmPackageFiles =
    _.flow(
      _.filter(filePath => filePath.indexOf('/elm-stuff/') === -1),
      _.sortBy(filePath => -filePath.length),
    )(await glob(path.join(repoDir, '**/elm-package.json')))


  const rootDirs = _.map(filePath => path.dirname(filePath), elmPackageFiles)

  // get elm files
  const files = await glob(path.join(repoDir, '**/*.elm'))

  // group files by root to which they belong
  const elmPackages = _.flow(
    _.flatMap((file) => {
      const rootDir = _.find((rootDir) => _.startsWith(rootDir, file), rootDirs)

      if (rootDir === undefined) {
        return []
      }

      return [{rootDir, file}]
    }),
    _.groupBy(({rootDir}) => rootDir),
    _.entries,
    _.map(([rootDir, files]) => {
      return {
        rootDir,
        elmPackageFile: _.find((elmPackageFile) => _.startsWith(rootDir, elmPackageFile), elmPackageFiles),
        files: _.flow( // remove elm-stuff files
          _.filter(({file, root}) => file.indexOf('/elm-stuff') === -1),
          _.map(({file}) => file)
        )(files)
      }
    })
  )(files)

  return elmPackages
}

module.exports = cloneRepo