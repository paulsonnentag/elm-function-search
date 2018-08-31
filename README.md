# Elm function search

Elm function search allows you to find code examples for all Elm functions

## search

search frontend


## crawler

aws lambda based repo crawler/parser

## api

### GET
Returns list of code snippets which use the function

```
GET https://elm-function-search.now.sh?package='elm-lang/core'&function='Json.Decode.int&version=5.1.1'
```

####Parameters

- **package:** name of the package
- **function:** full name of the function
- **version [optional]:** version of the package