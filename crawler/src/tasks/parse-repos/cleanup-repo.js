const fs = require('fs-extra')
const path = require('path')
const { TEMP_DIR } = require('../../../config.json')

async function cleanupRepo (name) {
  await fs.remove(path.join(TEMP_DIR, name, '..'))
}

module.exports = cleanupRepo
