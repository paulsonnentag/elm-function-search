module Tests exposing (..)

import Test exposing (..)
import Expect
import Ast
import Ast.Expression as Expression
import Ast.Statement exposing (Statement)
import Dict
import Parser exposing (Modules)


-- basic --


basicModules : Modules
basicModules =
    Dict.fromList
        [ ( "Html"
          , { package = "elm-lang/html"
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


basicTest : Test
basicTest =
    let
        result =
            [ { package = "elm-lang/html"
              , moduleName = "Html"
              , symbol = "text"
              , version = "1.0.0"
              }
            ]
    in
        describe "getReferences with different module types"
            [ test "functionImport" <|
                \_ ->
                    Expect.equal (Parser.getReferences basicModules functionImport) result
            , test "allInput" <|
                \_ ->
                    Expect.equal (Parser.getReferences basicModules allImport) result
            , test "namespaceImport" <|
                \_ ->
                    Expect.equal (Parser.getReferences basicModules namespacedImport) result
            , test "aliasedImport" <|
                \_ ->
                    Expect.equal (Parser.getReferences basicModules aliasedImport) result
            ]



-- counterProgram --


counterModules : Modules
counterModules =
    Dict.fromList
        [ ( "Html"
          , { package = "elm-lang/html"
            , version = "1.0.0"
            , moduleName = "Html"
            , symbols = [ "beginnerProgram", "div", "button", "text" ]
            }
          )
        , ( "Html.Events"
          , { package = "elm-lang/html"
            , version = "2.0.0"
            , moduleName = "Html.Events"
            , symbols = [ "onClick" ]
            }
          )
        ]


counterProgram : List Statement
counterProgram =
    crashableParse """
import Html exposing (..)
import Html.Events exposing (onClick)

main =
  beginnerProgram { model = model, view = view, update = update }


-- MODEL

model = 0


-- UPDATE

type Msg = Increment | Decrement


update msg model =
  case msg of
    Increment ->
      model + 1

    Decrement ->
      model - 1


-- VIEW

view model =
  div []
    [ button [ onClick Decrement ] [ text "-" ]
    , div [] [ text (toString model) ]
    , button [ onClick Increment ] [ text "+" ]
    ]
"""


realWorldTest : Test
realWorldTest =
    describe "getReferences of real world apps"
        [ test "counter program" <|
            \_ ->
                Expect.equal (Parser.getReferences counterModules counterProgram)
                    [ { package = "elm-lang/html", moduleName = "Html", symbol = "beginnerProgram", version = "1.0.0" }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "div", version = "1.0.0" }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "button", version = "1.0.0" }
                    , { package = "elm-lang/html", moduleName = "Html.Events", symbol = "onClick", version = "2.0.0" }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "text", version = "1.0.0" }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "div", version = "1.0.0" }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "text", version = "1.0.0" }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "button", version = "1.0.0" }
                    , { package = "elm-lang/html", moduleName = "Html.Events", symbol = "onClick", version = "2.0.0" }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "text", version = "1.0.0" }
                    ]
        ]



-- helper --


crashableParse : String -> List Statement
crashableParse str =
    case Ast.parse str of
        Ok ( _, _, statements ) ->
            statements

        Err err ->
            Debug.crash ("Invalid example: \n" ++ str ++ "\nErr:\n" ++ (toString err))
