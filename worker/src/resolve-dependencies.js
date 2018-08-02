const _ = require('lodash/fp')
const fetch = require('node-fetch')
const compareVersions = require('compare-versions')

class ResolveError extends Error {}

const getPackages = _.memoize(async () => _.keyBy('name', await fetchAllPackages()))

function fetchAllPackages () {
  return fetch('http://package.elm-lang.org/all-packages')
    .then(res => res.json())
}

function fetchModulesOfPackage (name, version) {
  return fetch (`http://package.elm-lang.org/packages/${name}/${version}/documentation.json`)
    .then(res => res.json())
}

async function getAllModules (dependencies) {
  const packages = await getPackages()
  const resolvedDependencies = getResolvedDependencies(packages, dependencies)
  const modules = await Promise.all(_.map(({name, version}) => getModulesOfPackage(name, version), resolvedDependencies))

  return _.flatten(modules)
}

function getResolvedDependencies (packages, dependencies) {
  return _.flow(
    _.toPairs,
    _.map(([packageName, version]) => {
      if (!packages[packageName]) {
        throw new ResolveError(`Dependency '${packageName}' doesn't exist`)
      }

      return {
        name: packageName,
        version: getAbsoluteVersion(packages[packageName], version)
      }
    })
  )(dependencies)
}

async function getModulesOfPackage (name, version) {
  const modules = await fetchModulesOfPackage(name, version)

  return _.map(module => {
    const symbols = _.map(({name}) => name, module.values)

    return {
      version: version,
      package: name,
      moduleName: module.name,
      symbols: symbols
    }
  }, modules)
}

const VERSION_REGEX = /^([0-9]+\.[0-9]+\.[0-9]+) (<=|<) v (<=|<) ([0-9]+\.[0-9]+\.[0-9]+)$/

function getAbsoluteVersion (package, version) {
  const {versions} = package
  const match = version.match(VERSION_REGEX)

  if (!match) {
    throw new ResolveError(`Dependency '${package.name}' has an invalid version format '${version}'`)
  }

  const [, minVersion, lowerComparator, upperComparator, maxVersion] = match

  // find latest matching version
  // compareVersion: a < b => -1; a == b => 0; a > b => 1
  const absoluteVersion = _.find((absoluteVersion) => {
    const lowerComparison = compareVersions(minVersion, absoluteVersion)
    const upperComparison = compareVersions(absoluteVersion, maxVersion)

    return (
      ((lowerComparator === '<' && lowerComparison === -1) || (lowerComparator === '<=' && lowerComparison <= 0)) &&
      ((upperComparator === '<' && upperComparison === -1) || (upperComparator === '<=' && upperComparison <= 0))
    )
  }, versions)

  if (!absoluteVersion) {
    throw new ResolveError(`Dependency '${package.name}' has no matching version for '${version}'`)
  }

  return absoluteVersion
}

module.exports = {
  getAllModules,
  ResolveError
}
