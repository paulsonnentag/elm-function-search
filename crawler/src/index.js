const parseRepo = require('./tasks/parse-repo')

;(async () => {
    const timestamp = Date.now()

    const result = await parseRepo('rtfeldman/elm-spa-example')

    console.log(result)

    console.log('time', Date.now() - timestamp, result.length)
})()

