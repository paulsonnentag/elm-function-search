module Parser exposing (getReferences, scopeFromImports, Modules)

import Ast.Statement exposing (Statement(..), ExportSet(..))
import Ast.Expression exposing (Expression(..))
import List.Extra as List
import Dict exposing (Dict)


type alias Reference =
    { package : String
    , moduleName : String
    , symbol : String
    , version : String
    }


type alias Scope =
    Dict String ScopeValue


type ScopeValue
    = ModuleValue Module
    | SymbolValue Symbol
    | LocalValue


type alias Modules =
    Dict String Module


type alias Symbol =
    { version : String
    , package : String
    , moduleName : String
    , symbol : String
    }


type alias Module =
    { version : String
    , package : String
    , moduleName : String
    , symbols : List String
    }


type alias Import =
    { module_ : Module
    , alias : Maybe String
    , exports : Maybe ExportSet
    }


getReferences : Modules -> List Statement -> List Reference
getReferences modules allStatements =
    let
        statementsWithImports =
            allStatements
                |> List.filterNot isComment
                |> dropModule

        imports =
            statementsWithImports
                |> List.takeWhile isImportStatement
                |> List.filterMap (getImport modules)

        statements =
            List.drop (List.length imports) statementsWithImports

        scope =
            scopeFromImports imports
    in
        List.concatMap (getReferencesInStatement scope) statements


getReferencesInStatement : Scope -> Statement -> List Reference
getReferencesInStatement scope statement =
    case statement of
        ModuleDeclaration _ _ ->
            Debug.log "unexpected module declaration" []

        PortModuleDeclaration _ _ ->
            Debug.log "unexpected module declaration" []

        EffectModuleDeclaration _ _ _ ->
            Debug.log "unexpected module declaration" []

        ImportStatement _ _ _ ->
            Debug.log "unexpected import statement" []

        TypeAliasDeclaration _ _ ->
            []

        TypeDeclaration _ _ ->
            []

        PortTypeDeclaration _ _ ->
            []

        PortDeclaration _ _ _ ->
            Debug.crash "not implemented"

        FunctionTypeDeclaration _ _ ->
            []

        FunctionDeclaration name args body ->
            getReferencesInExpression scope body

        InfixDeclaration _ _ _ ->
            Debug.crash "not implemented"

        Comment _ ->
            []


getReferencesInExpression : Scope -> Expression -> List Reference
getReferencesInExpression scope expression =
    case expression of
        Character _ ->
            []

        String _ ->
            []

        Integer _ ->
            []

        Float _ ->
            []

        Variable nameList ->
            let
                name =
                    String.join "." nameList
            in
                case Dict.get name scope of
                    Just (SymbolValue { package, moduleName, symbol, version }) ->
                        [ { package = package
                          , moduleName = moduleName
                          , symbol = symbol
                          , version = version
                          }
                        ]

                    _ ->
                        []

        Access (Variable moduleNameList) name ->
            let
                moduleName =
                    String.join "." moduleNameList

                symbolName =
                    List.head name
            in
                case ( Dict.get moduleName scope, symbolName ) of
                    ( Just (ModuleValue { package, moduleName, symbols, version }), Just symbolName ) ->
                        if List.member symbolName symbols then
                            [ { package = package
                              , moduleName = moduleName
                              , symbol = symbolName
                              , version = version
                              }
                            ]
                        else
                            []

                    _ ->
                        []

        List expressions ->
            List.concatMap (getReferencesInExpression scope) expressions

        Tuple expressions ->
            List.concatMap (getReferencesInExpression scope) expressions

        Access expression name ->
            getReferencesInExpression scope expression

        AccessFunction _ ->
            []

        Record entries ->
            List.concatMap (\( _, expression ) -> (getReferencesInExpression scope expression)) entries

        RecordUpdate name entries ->
            List.concatMap (\( _, expression ) -> (getReferencesInExpression scope expression)) entries

        If condition trueCase falseCase ->
            (getReferencesInExpression scope condition)
                ++ (getReferencesInExpression scope trueCase)
                ++ (getReferencesInExpression scope falseCase)

        Let entries body ->
            (List.concatMap (\( _, value ) -> (getReferencesInExpression scope value)) entries)
                ++ (getReferencesInExpression scope body)

        Case value cases ->
            (getReferencesInExpression scope value)
                ++ (List.concatMap (\( _, body ) -> (getReferencesInExpression scope body)) cases)

        Lambda args body ->
            (getReferencesInExpression scope body)

        Application function arg ->
            (getReferencesInExpression scope function)
                ++ (getReferencesInExpression scope arg)

        BinOp operand1 operator operand2 ->
            (getReferencesInExpression scope operand1)
                ++ (getReferencesInExpression scope operator)
                ++ (getReferencesInExpression scope operand2)


scopeFromImports : List Import -> Scope
scopeFromImports imports =
    List.foldr
        (\{ module_, exports, alias } scope ->
            scope
                |> addModuleToScope module_ alias
                |> addExportsToScope module_ exports
        )
        (Dict.fromList [])
        imports


addModuleToScope : Module -> Maybe String -> Scope -> Scope
addModuleToScope module_ alias scope =
    case alias of
        Nothing ->
            Dict.insert module_.moduleName (ModuleValue module_) scope

        Just aliasName ->
            Dict.insert aliasName (ModuleValue module_) scope


addExportsToScope : Module -> Maybe ExportSet -> Scope -> Scope
addExportsToScope module_ exports_ scope =
    case exports_ of
        Nothing ->
            scope

        Just exportSet ->
            case exportSet of
                AllExport ->
                    List.foldr
                        (\symbol scope ->
                            Dict.insert
                                symbol
                                (SymbolValue
                                    { version = module_.version
                                    , package = module_.package
                                    , moduleName = module_.moduleName
                                    , symbol = symbol
                                    }
                                )
                                scope
                        )
                        scope
                        module_.symbols

                SubsetExport values ->
                    List.foldr
                        (\exportValue scope ->
                            case exportValue of
                                FunctionExport name ->
                                    Dict.insert
                                        name
                                        (SymbolValue
                                            { version = module_.version
                                            , package = module_.package
                                            , moduleName = module_.moduleName
                                            , symbol = name
                                            }
                                        )
                                        scope

                                -- Ignore types for now
                                TypeExport _ _ ->
                                    scope

                                _ ->
                                    Debug.crash ("Invlaid nested ExportSet value: " ++ (toString exportValue))
                        )
                        scope
                        values

                _ ->
                    Debug.crash ("Invalid top level ExportSet value: " ++ (toString exportSet))


isComment : Statement -> Bool
isComment statement =
    case statement of
        Comment _ ->
            True

        _ ->
            False


isImportStatement : Statement -> Bool
isImportStatement statement =
    case statement of
        ImportStatement _ _ _ ->
            True

        _ ->
            False


getImport : Modules -> Statement -> Maybe Import
getImport modules statement =
    case statement of
        ImportStatement moduleName alias exports ->
            case Dict.get (String.join "." moduleName) modules of
                Just module_ ->
                    Just
                        { module_ = module_
                        , alias = alias
                        , exports = exports
                        }

                Nothing ->
                    Debug.log ("ignore unresolved module: " ++ (toString moduleName))
                        Nothing

        _ ->
            Nothing


dropModule : List Statement -> List Statement
dropModule statements =
    case statements of
        (ModuleDeclaration _ _) :: rest ->
            rest

        _ ->
            statements
