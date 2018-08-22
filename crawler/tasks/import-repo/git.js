const _ = require('lodash/fp')
const git = require('simple-git/promise')
const util = require('util')
const exec = util.promisify(require('child_process').exec)

const ensureGitExists = _.memoize(async () => {
  if(!(await hasGit())) {
    await require('lambda-git')()
  }
})

async function hasGit () {
  try {
    await exec('git --version')
  } catch (err) {
    return false
  }
  return true
}

module.exports = async (baseDir) => {
  await ensureGitExists()

  return git(baseDir)
}