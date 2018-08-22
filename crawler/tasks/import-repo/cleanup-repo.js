const fs = require('fs-extra')
const path = require('path')

const { TEMP_REPO_DIR = '/tmp/elm-function-search' } = process.env

module.exports = async (name) => {
  return fs.remove(path.join(TEMP_REPO_DIR, name, '..'))
}
