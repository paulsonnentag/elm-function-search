const {Main} = require('./build/worker.js')

const worker = Main.worker();
const pendingRequests = {}

const getId = (() => {
  let id = 0
  return () => id++
})()

worker.ports.outputPort.subscribe(({ requestId, type, data }) => {
  const request = pendingRequests[requestId]
  delete pendingRequests[requestId]

  switch (type) {
    case 'error':
      request.reject(data.errors)
      return

    case 'success':
      request.resolve(data.references)
      return
  }
})

function parseReferences (modules, source) {
  return new Promise((resolve, reject) => {
    const requestId = getId()

    pendingRequests[requestId] = {resolve, reject}

    worker.ports.inputPort.send({ requestId, modules, source })
  })
}

module.exports = {
  parseReferences
}