const express = require('express')
const cors = require('cors')
const app = express()

const examples = require('./routes/examples')
const symbols = require('./routes/symbols')

app.use(cors())

app.set('json spaces', 2);

app.use('/symbols', symbols)
//app.get('/examples' examples)

app.listen(3000)