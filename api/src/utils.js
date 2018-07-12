function errorHandler (req, res) {
  return (err) => {
    console.error(`${req.method} ${req.path}:`, err)
    res.sendStatus(500)
  }
}

module.exports = {
  errorHandler
}