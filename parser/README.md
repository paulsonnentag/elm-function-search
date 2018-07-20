# Parser

## Todo

- [ ] support all modules
  - [ ] effect modules
  - [ ] port module
- [ ] add default packages
- [ ] implement shadowing of variables

## Approach

- Find elm-package.json in each repo

- load published packages into graph

- differentiate repo between apps (not published) and libraries (published)
  - app
    - parse latest version branch

  - library (lookup repo id to check if repo has been published)
    - parse latest commit on master

- parse elm files which belong grouped by elm-package.json
  - resolve exact
  - implement recursive lookup of symbols
