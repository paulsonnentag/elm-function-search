const express = require('express')
const cors = require('cors')
const app = express()

const examples = require('./routes/examples')
const search = require('./routes/search')

app.use(cors())

app.set('json spaces', 2);

app.use('/search', search)
//app.get('/examples' examples)

app.listen(3000)