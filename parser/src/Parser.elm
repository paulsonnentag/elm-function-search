module Parser exposing (getReferences, parseReferences, scopeFromImports, Module, Modules, Reference)

import Ast
import Ast.Statement exposing (Statement(..), ExportSet(..))
import Ast.Expression exposing (Expression(..))
import List.Extra as List
import Dict exposing (Dict)


type alias Reference =
    { package : String
    , moduleName : String
    , symbol : String
    , version : String
    , column : Int
    , line : Int
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


defaultImportStatements : List Statement
defaultImportStatements =
    [ ImportStatement [ "Basics" ] Nothing (Just AllExport) { line = 0, column = 0 }
    , ImportStatement [ "List" ] Nothing (Just (SubsetExport ([ TypeExport "List" Nothing, FunctionExport "::" ]))) { line = 0, column = 0 }
    , ImportStatement [ "Maybe" ] Nothing (Just (SubsetExport ([ TypeExport "Maybe" (Just (SubsetExport ([ FunctionExport "Just", FunctionExport "Nothing" ]))) ]))) { line = 0, column = 0 }
    , ImportStatement [ "Result" ] Nothing (Just (SubsetExport ([ TypeExport "Result" (Just (SubsetExport ([ FunctionExport "Ok", FunctionExport "Err" ]))) ]))) { line = 0, column = 0 }
    , ImportStatement [ "String" ] Nothing Nothing { line = 0, column = 0 }
    , ImportStatement [ "Tuple" ] Nothing Nothing { line = 0, column = 0 }
    , ImportStatement [ "Debug" ] Nothing Nothing { line = 0, column = 0 }
    , ImportStatement [ "Platform" ] Nothing (Just (SubsetExport ([ TypeExport "Program" Nothing ]))) { line = 0, column = 0 }
    , ImportStatement [ "Platform", "Cmd" ] Nothing (Just (SubsetExport ([ TypeExport "Cmd" Nothing, FunctionExport "!" ]))) { line = 0, column = 0 }
    , ImportStatement [ "Platform", "Sub" ] Nothing (Just (SubsetExport ([ TypeExport "Sub" Nothing ]))) { line = 0, column = 0 }
    ]


parseReferences : Modules -> String -> Result (List String) (List Reference)
parseReferences modules source =
    case Ast.parse source of
        Ok ( _, _, statements ) ->
            Ok (getReferences modules statements)

        Err ( _, _, errors ) ->
            Err errors


getReferences : Modules -> List Statement -> List Reference
getReferences modules allStatements =
    let
        statementsWithImports =
            allStatements
                |> List.filterNot isComment
                |> dropModule

        importStatements =
            List.takeWhile isImportStatement statementsWithImports

        statements =
            List.drop (List.length importStatements) statementsWithImports

        imports =
            (importStatements ++ defaultImportStatements)
                |> List.filterMap (getImport modules)

        scope =
            scopeFromImports imports
    in
        List.concatMap (getReferencesInStatement scope) statements


getReferencesInStatement : Scope -> Statement -> List Reference
getReferencesInStatement scope statement =
    case statement of
        ModuleDeclaration _ _ _ ->
            Debug.log "unexpected module declaration" []

        PortModuleDeclaration _ _ _ ->
            Debug.log "unexpected module declaration" []

        EffectModuleDeclaration _ _ _ _ ->
            Debug.log "unexpected module declaration" []

        ImportStatement _ _ _ _ ->
            Debug.log "unexpected import statement" []

        TypeAliasDeclaration _ _ _ ->
            []

        TypeDeclaration _ _ _ ->
            []

        PortTypeDeclaration _ _ _ ->
            []

        PortDeclaration _ _ _ _ ->
            Debug.crash "not implemented"

        FunctionTypeDeclaration _ _ _ ->
            []

        FunctionDeclaration name args body _ ->
            getReferencesInExpression scope body

        InfixDeclaration _ _ _ _ ->
            Debug.crash "not implemented"

        Comment _ _ ->
            []


getReferencesInExpression : Scope -> Expression -> List Reference
getReferencesInExpression scope expression =
    case expression of
        Character _ _ ->
            []

        String _ _ ->
            []

        Integer _ _ ->
            []

        Float _ _ ->
            []

        Variable nameList meta ->
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
                          , line = meta.line
                          , column = meta.column
                          }
                        ]

                    _ ->
                        []

        Access (Variable moduleNameList _) name meta ->
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
                              , line = meta.line
                              , column = meta.column
                              }
                            ]
                        else
                            []

                    _ ->
                        []

        List expressions _ ->
            List.concatMap (getReferencesInExpression scope) expressions

        Tuple expressions _ ->
            List.concatMap (getReferencesInExpression scope) expressions

        Access expression name _ ->
            getReferencesInExpression scope expression

        AccessFunction _ _ ->
            []

        Record entries _ ->
            List.concatMap (\( _, expression ) -> (getReferencesInExpression scope expression)) entries

        RecordUpdate name entries _ ->
            List.concatMap (\( _, expression ) -> (getReferencesInExpression scope expression)) entries

        If condition trueCase falseCase _ ->
            (getReferencesInExpression scope condition)
                ++ (getReferencesInExpression scope trueCase)
                ++ (getReferencesInExpression scope falseCase)

        Let entries body _ ->
            (List.concatMap (\( _, value ) -> (getReferencesInExpression scope value)) entries)
                ++ (getReferencesInExpression scope body)

        Case value cases _ ->
            (getReferencesInExpression scope value)
                ++ (List.concatMap (\( _, body ) -> (getReferencesInExpression scope body)) cases)

        Lambda args body _ ->
            (getReferencesInExpression scope body)

        Application function arg _ ->
            (getReferencesInExpression scope function)
                ++ (getReferencesInExpression scope arg)

        BinOp operand1 operator operand2 _ ->
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
        Comment _ _ ->
            True

        _ ->
            False


isImportStatement : Statement -> Bool
isImportStatement statement =
    case statement of
        ImportStatement _ _ _ _ ->
            True

        _ ->
            False


getImport : Modules -> Statement -> Maybe Import
getImport modules statement =
    case statement of
        ImportStatement moduleName alias exports _ ->
            case Dict.get (String.join "." moduleName) modules of
                Just module_ ->
                    Just
                        { module_ = module_
                        , alias = alias
                        , exports = exports
                        }

                Nothing ->
                    Nothing

        _ ->
            Nothing


dropModule : List Statement -> List Statement
dropModule statements =
    case statements of
        (ModuleDeclaration _ _ _) :: rest ->
            rest

        (EffectModuleDeclaration _ _ _ _) :: rest ->
            rest

        (PortModuleDeclaration _ _ _) :: rest ->
            rest

        _ ->
            statements
