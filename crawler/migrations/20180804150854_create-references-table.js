exports.up = (knex) => {
  return knex.schema.createTable('references', (table) => {
    table.increments('id').notNullable()
    table.string('package').notNullable()
    table.string('module').notNullable()
    table.string('symbol').notNullable()
    table.string('version').notNullable()
    table.string('file').notNullable()
    table.integer('start_col').notNullable()
    table.integer('start_line').notNullable()
    table.integer('end_col').notNullable()
    table.integer('end_line').notNullable()
    table.string('repo_owner').notNullable()
    table.string('repo_name').notNullable()
    table.string('commit_hash').notNullable()
    table.foreign(['repo_owner', 'repo_name']).references(['repos.owner', 'repos.name'])
  })
}

exports.down = (knex) => {
  return knex.schema.dropTableIfExists('references')
}
