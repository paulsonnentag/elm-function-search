const {DATABASE_HOST, DATABASE_USER, DATABASE_SECRET, DATABASE_NAME} = process.env

module.exports = {
  development: {
    client: 'pg',
    connection: 'postgres://localhost/elm_function_search_development',
    migrations: {
      directory: './migrations'
    },
    useNullAsDefault: true
  },

  cloud: {
    client: 'pg',
    connection: `postgres://${DATABASE_USER}:${DATABASE_SECRET}@${DATABASE_HOST}:5432/${DATABASE_NAME}`,
    migrations: {
      directory: './migrations'
    },
    useNullAsDefault: true
  }
}