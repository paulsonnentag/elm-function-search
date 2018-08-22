exports.up = (knex) => {
  return knex.schema.createTable('repos', (table) => {
    table.string('owner').notNullable()
    table.string('name').notNullable()
    table.integer('stars').notNullable()
    table.timestamp('last_updated').notNullable()
    table.string('license').defaultTo(null)
    table.primary(['owner', 'name'])
  })
}

exports.down = (knex) => {
  return knex.schema.dropTableIfExists('repos')
}
