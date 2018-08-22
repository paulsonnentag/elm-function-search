const fs = require('fs-extra')
const [,, filePath] = process.argv

console.log(fs.readFileSync(filePath, 'utf-8'))
