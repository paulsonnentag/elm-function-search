const _ = require('lodash/fp')
const AWS = require('aws-sdk');
const {REPO_QUEUE_NAME, ACCOUNT_ID} = process.env

// Create an SQS service object
const sqs = new AWS.SQS({apiVersion: '2012-11-05'});

module.exports = async ({ owner, name, stars, lastUpdated, license}) => {
  const params = {
    DelaySeconds: 10,
    MessageBody: JSON.stringify({
      owner,
      name,
      stars,
      license,
      lastUpdated
    }),
    QueueUrl: `https://sqs.us-west-1.amazonaws.com/${ACCOUNT_ID}/${REPO_QUEUE_NAME}`
  }

  return new Promise((resolve, reject) => {
    sqs.sendMessage(params, (err, data) => {
      if (err) {
        reject(err)
        return
      }
      resolve(data)
    })
  })
}
