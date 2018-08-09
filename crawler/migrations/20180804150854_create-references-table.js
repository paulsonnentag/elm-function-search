exports.up = (knex) => {
  return knex.schema.createTable('references', (table) => {
    table.string('package').notNullable()
    table.string('module').notNullable()
    table.string('symbol').notNullable()
    table.string('version').notNullable()
    table.string('url').notNullable()
    table.integer('col').notNullable()
    table.integer('row').notNullable()
  })
}

exports.down = (knex) => {
  return knex.schame.dropTableIfExists('references')
}
