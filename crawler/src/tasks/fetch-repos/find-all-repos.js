const _ = require('lodash/fp')
const fetch = require('node-fetch')
const querystring = require('querystring')
const { GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET } = require('../../config.json')

async function findAllRepos (query) {
  const PAGE_SIZE = 100
  const MAX_PAGE = 10

  let currentPage = 1
  let timestamp = '2970-01-01' // initialize with a timestamp in the future
  let result = []

  while (true) {
    const { total, repos } = await findRepos({
      pageSize: PAGE_SIZE,
      page: currentPage,
      query: `${query} pushed:<=${timestamp}`
    })

    const newRepos =
      _.flow(
        _.map(normalizeRepo),
        _.filter(repo => !_.some(({ name, owner }) =>  owner == repo.owner && name == repo.name, result))
      )(repos)


    result = result.concat(newRepos)

    if (currentPage * PAGE_SIZE < total) {
      if (currentPage < MAX_PAGE) {
        currentPage++
      } else {
        currentPage = 1
        timestamp = _.last(newRepos).lastUpdated.slice(0, 10) // just keep date part of timestamp
      }
      continue
    }

    break
  }

  return result
}


function normalizeRepo (repo) {
  return {
    owner: repo.owner.login === 'elm' ? 'elm-lang' : repo.owner.login,
    name: repo.name,
    lastUpdated: repo.updated_at < repo.pushed_at ? repo.updated_at : repo.pushed_at,
    license: repo.license && repo.license.key,
    stars: repo.stargazers_count
  }
}


function findRepos ({page, pageSize, query, sort = 'updated'}) {
  return apiGet(`search/repositories`, {
    q: query,
    page,
    per_page: pageSize,
    sort,
  })
    .then(data => ({
      repos: data.items,
      total: data.total_count
    }))
}

async function apiGet (resource, params) {
  const query = querystring.stringify({
    ...params,
    client_id: GITHUB_CLIENT_ID,
    client_secret: GITHUB_CLIENT_SECRET
  })

  const url = `https://api.github.com/${resource}?${query}`

  console.log('url:', url)

  return fetch(url)
    .then(async (response) => {
      console.log('response status: ', response.status)

      if (response.status === 403 && response.headers.get('x-ratelimit-remaining') === '0') {
        var waitTime = (parseInt(response.headers.get('x-ratelimit-reset'), 10) * 1000) + 500 - Date.now()

        if (waitTime > 0) {
          console.log(`sleep ${waitTime / 1000} second(s)`)
          await sleep(waitTime)
        }

        return apiGet(resource, params)
      }

      if (!response.ok) {
        return Promise.reject(response.json())
      }

      return response.json()
    })
}

async function sleep (ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

module.exports = findAllRepos
