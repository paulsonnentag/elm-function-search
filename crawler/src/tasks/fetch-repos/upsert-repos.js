async function upsertRepos (knex, repos) {
  knex.raw(getUpsertQuery(repos))
}

function getUpsertQuery (repos) {
  const values =
  _.map(({owner, name, lastUpdated, stars, license}) => (
    `('${owner}', '${name}', TIMESTAMP '${formatDate(lastUpdated)}', ${stars}, ${license ? `'${license}'` : 'null'})`
  ), repos).join(',\n')

  return `
    INSERT INTO repos (owner, name, last_updated, stars, license)
    VALUES
      ${values}
    ON CONFLICT (owner, name)
    DO UPDATE SET
      last_updated = EXCLUDED.last_updated,
      stars = EXCLUDED.stars,
      license = EXCLUDED.license;
  `
}

// turn github timestamp into postgres timestamp
// Example: '2018-08-03T09:47:01Z' => '2018-08-03 09:47:01'
// Reference: https://www.postgresql.org/docs/9.1/static/datatype-datetime.html
function formatDate (date) {
  return date.replace('T', ' ').replace('Z', '')
}

module.exports = upsertRepos