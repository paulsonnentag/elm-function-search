module Tests exposing (..)

import Test exposing (..)
import Expect
import Ast
import Ast.Expression as Expression
import Ast.Statement exposing (Statement)
import Dict
import Parser exposing (Modules)


-- basic examples --


basicModules : Modules
basicModules =
    Dict.fromList
        [ ( "Html"
          , { package = "elm-lang/core"
            , version = "1.0.0"
            , moduleName = "Html"
            , symbols = [ "text" ]
            }
          )
        ]


functionImport : List Statement
functionImport =
    crashableParse """
import Html exposing (text)

view : String -> Html msg
view = text "hello world"
"""


allImport : List Statement
allImport =
    crashableParse """
import Html exposing (..)

view : String -> Html msg
view = text "hello world"
"""


namespacedImport : List Statement
namespacedImport =
    crashableParse """
import Html

view : String -> Html msg
view = Html.text "hello world"
"""


aliasedImport : List Statement
aliasedImport =
    crashableParse """
import Html as H

view : String -> Html msg
view = H.text "hello world"
"""


basic : Test
basic =
    let
        result =
            [ { package = "elm-lang/core"
              , moduleName = "Html"
              , symbol = "text"
              , version = "1.0.0"
              }
            ]
    in
        describe "getReferences"
            [ test "functionImport" <|
                \_ ->
                    Expect.equal result (Parser.getReferences basicModules functionImport)
            , test "allInput" <|
                \_ ->
                    Expect.equal result (Parser.getReferences basicModules allImport)
            , test "namespaceImport" <|
                \_ ->
                    Expect.equal result (Parser.getReferences basicModules namespacedImport)
            , test "aliasedImport" <|
                \_ ->
                    Expect.equal result (Parser.getReferences basicModules aliasedImport)
            ]



-- helper --


crashableParse : String -> List Statement
crashableParse str =
    case Ast.parse str of
        Ok ( _, _, statements ) ->
            statements

        Err err ->
            Debug.crash ("Invalid example: \n" ++ str ++ "\nErr:\n" ++ (toString err))
