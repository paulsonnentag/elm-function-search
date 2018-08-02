const { getAllModules, ResolveError } = require('./resolve-dependencies')

;(async () => {
  try {
    const package = require('../example-package.json')
    const modules = await getAllModules(package.dependencies)

    console.log(modules)

  } catch (e) {
    if (e instanceof ResolveError) {
      console.warn("Failed to resolve package", e)
    } else {
      throw e
    }
  }
})()
