const _ = require('lodash/fp')
const fetch = require('node-fetch')

const getAllPackages = _.memoize(async () => _.flow(
  _.toPairs,
  _.map(([name, versions]) => ({ name, versions })),
  _.keyBy('name')
  )(await fetchAllPackages()))

function fetchAllPackages () {
  return fetch('http://package.elm-lang.org/all-packages')
    .then(res => res.json())
}

function fetchModulesOfPackage (name, version) {
  return fetch(`http://package.elm-lang.org/packages/${name}/${version}/docs.json`)
    .then(res => res.json())
}

module.exports = {
  getAllPackages,
  fetchModulesOfPackage
}