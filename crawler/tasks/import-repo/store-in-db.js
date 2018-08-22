const path = require('path')
const _ = require('lodash/fp')
const { TEMP_REPO_DIR = '/tmp/elm-function-search' } = process.env

module.exports = async (knex, {repo, references, commitHash}) => {
  await updateRepo(knex, repo)
  await updateReferences(knex, {repo, references, commitHash})
}

async function updateRepo (knex, {owner, name, lastUpdated, stars, license}) {
  await knex.raw(`
    INSERT INTO repos (owner, name, last_updated, stars, license)
    VALUES
      ('${owner}', '${name}', TIMESTAMP '${formatDate(lastUpdated)}', ${stars}, ${license ? `'${license}'` : 'null'})
    ON CONFLICT (owner, name)
    DO UPDATE SET
      last_updated = EXCLUDED.last_updated,
      stars = EXCLUDED.stars,
      license = EXCLUDED.license;
  `)
}

// turn github timestamp into postgres timestamp
// Example: '2018-08-03T09:47:01Z' => '2018-08-03 09:47:01'
// Reference: https://www.postgresql.org/docs/9.1/static/datatype-datetime.html
function formatDate (date) {
  return date.replace('T', ' ').replace('Z', '')
}

async function updateReferences (knex, {repo, references, commitHash}) {
  await (knex('references')
    .where({
      repo_owner: repo.owner,
      repo_name: repo.name
    })
    .del())

  const rows = getReferencesRows({repo, references, commitHash})

  await (knex('references')
    .insert(rows))

  console.log(`inserted ${rows.length} reference(s)`)
}

function getReferencesRows ({repo, references, commitHash}) {
  const pathPrefixLength = path.join(TEMP_REPO_DIR, `${repo.owner}/${repo.name}/`).length

  return _.flow(
    _.filter(({ result }) =>  result.type === 'success'),
    _.flatMap(({ file, result }) => {
      return _.map(({package, module, version, symbol, sourceLocation}) => ({
        package,
        module,
        version,
        symbol,
        file: file.slice(pathPrefixLength), // drop local temp dir prefix
        commit_hash: commitHash,
        start_col: sourceLocation.start.col,
        start_line: sourceLocation.start.line,
        end_col: sourceLocation.start.col,
        end_line: sourceLocation.start.line,
        repo_owner: repo.owner,
        repo_name: repo.name
      }), result.data.references)
    })
  )(references)
}


