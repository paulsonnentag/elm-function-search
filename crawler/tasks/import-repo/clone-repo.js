const _ = require('lodash/fp')
const util = require('util')
const fs = require('fs-extra')
const path = require('path')
const glob = util.promisify(require('glob'))
const git = require('./git')
const registry = require('./package-registry')

const { TEMP_REPO_DIR = '/tmp/elm-function-search' } = process.env

module.exports = async name => {
  const repoDir = path.join(TEMP_REPO_DIR, name)
  const commitHash = await fetchRepo(repoDir, name)

  return {
    commitHash,
    packages: await getElmPackages(repoDir)
  }
}

async function fetchRepo(repoDir, name) {
  const packages = await registry.getAllPackages()

  await fs.emptyDir(repoDir)
  const repo = await git(repoDir)

  await repo.clone(`https://github.com/${name}.git`, '.')

  // if repos has been published to registry checkout latest published version
  const package = packages[name]
  if (package) {
    const latestVersion = _.last(package.versions)

    await repo.checkout(latestVersion)
  }

  // return hash off current commit
  return (await repo.log({n: 1})).latest.hash
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
  return _.flow(
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
}
