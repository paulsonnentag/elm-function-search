const _ = require('lodash/fp')
const util = require('util')
const path = require('path')
const exec = util.promisify(require('child_process').exec)

module.exports = async (modules, filePath) => {
  const ast = await getAst(filePath)
  return getReferences(modules, ast)
}

async function getAst (filePath) {
  const {stdout, stderr} = await exec(`node ${path.join(__dirname, 'cat.js')} ${filePath} | ${path.join(__dirname, 'lib/elm-format')} --stdin --json`)

  if (stderr) {
    return Promise.reject(stderr)
  }

  return Promise.resolve(JSON.parse(stdout))
}

function getReferences (modules, obj) {
  // root of ast
  if (!obj.type && obj.body) {
    return _.flatMap((obj) => getReferences(modules, obj), obj.body)
  }

  // skip nodes which haven't been implemented yet and are currently represented as strings
  if (!obj.type) {
    return []
  }

  switch (obj.type) {


    // LITERALS

    case 'IntLiteral':
    case 'UnitLiteral':
    case 'DecimalInt':
    case 'HexadecimalInt':
      return []


    // REFERENCES

    case 'ExternalReference': {
      const module = modules[obj.module]

      if (!module) {
        return []
      }

      return [{
        package: module.package,
        module: obj.module,
        version: module.version,
        symbol: obj.identifier,
        sourceLocation: obj.sourceLocation
      }]
    }

    // TODO: implement variable references
    case 'VariableReference':
      return []


    // COMPLEX CONSTRUCTS

    case 'IfExpression':
      return _.flatten([
        getReferences(modules, obj.if),
        getReferences(modules, obj.then),
        getReferences(modules, obj.else)
      ])

    case 'RecordAccess':
      return getReferences(modules, obj.record)

    case 'LetExpression':
      return (
        _.flatMap((obj) => getReferences(modules, obj), obj.declarations)
          .concat(getReferences(modules, obj.body))
      )

    case 'AnonymousFunction':
      return getReferences(modules, obj.body)

    case 'CaseExpression':
      return (
        getReferences(modules, obj.subject)
          .concat(
            _.flatMap(({pattern, body}) => [
              getReferences(modules, pattern),
              getReferences(modules, body)
            ], obj.patterns)
          )
      )

    case 'Definition':
      return getReferences(modules, obj.expression)

    case 'FunctionApplication':
      return (
        getReferences(modules, obj.function)
          .concat(
            _.flatMap((obj) => getReferences(modules, obj), obj.arguments)
          )
      )

    case 'BinaryOperatorList':
      return (
        getReferences(modules, obj.first)
          .concat(
            _.flatMap((obj) => getReferences(modules, obj), obj.operations)
          )
      )

    case 'UnaryOperator':
      return _.flatten([
        getReferences(modules, obj.operator),
        getReferences(modules, obj.term)
      ])

    case 'ListLiteral':
      return _.flatMap((obj) => getReferences(modules, obj), obj.terms)

    case 'TupleLiteral':
      return _.flatMap((obj) => getReferences(modules, obj), obj.terms)

    case 'RecordUpdate':
      return _.flatMap((obj) => getReferences(modules, obj), obj.fields)

    case 'RecordLiteral':
      return _.flatMap((obj) => getReferences(modules, obj), obj.fields)


    // FALLBACK

    default:
      console.log('unhandled type', obj.type)
      return []

  }
}