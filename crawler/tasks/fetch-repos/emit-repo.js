const AWS = require('aws-sdk');
const {promisify} = require('utils')
const {AWS_REGION, } = process.env
// Set the region
AWS.config.update({region: AWS_REGION})

// Create an SQS service object
const sqs = new AWS.SQS({apiVersion: '2012-11-05'});

const sendMessage = promisify(sqs.sendMessage)

function emitRepo ({ owner, name, stars, lastUpdated, license}) {
  return sendMessage({
    DelaySeconds: 10,
    MessageAttributes: {
      owner,
      name,
      stars,
      license,
      lastUpdated
    },
    MessageBody: `parse ${owner}/${name}`,
    QueueUrl: "SQS_QUEUE_URL"
  })
}


module.exports = emitRepo

