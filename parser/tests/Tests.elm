module Tests exposing (..)

import Test exposing (..)
import Expect
import Ast
import Ast.Statement exposing (Statement)
import Dict
import Parser exposing (Modules)


-- basic --


defaultModules : Modules
defaultModules =
    Dict.fromList
        [ ( "Basics"
          , { package = "elm-lang/core"
            , version = "1.0.0"
            , moduleName = "Basics"
            , symbols = [ "toString", "==" ]
            }
          )
        , ( "List"
          , { package = "elm-lang/core"
            , version = "1.0.0"
            , moduleName = "List"
            , symbols = [ "::", "head" ]
            }
          )
        , ( "Maybe"
          , { package = "elm-lang/core"
            , version = "1.0.0"
            , moduleName = "Maybe"
            , symbols = [ "withDefault" ]
            }
          )
        , ( "Result"
          , { package = "elm-lang/core"
            , version = "1.0.0"
            , moduleName = "Result"
            , symbols = [ "withDefault" ]
            }
          )
        , ( "String"
          , { package = "elm-lang/core"
            , version = "1.0.0"
            , moduleName = "String"
            , symbols = [ "toInt" ]
            }
          )
        , ( "Tuple"
          , { package = "elm-lang/core"
            , version = "1.0.0"
            , moduleName = "Tuple"
            , symbols = [ "first" ]
            }
          )
        , ( "Debug"
          , { package = "elm-lang/core"
            , version = "1.0.0"
            , moduleName = "Debug"
            , symbols = [ "log" ]
            }
          )
        , ( "Platform"
          , { package = "elm-lang/core"
            , version = "1.0.0"
            , moduleName = "Platform"
            , symbols = [ "sendToApp" ]
            }
          )
        , ( "Platform.Cmd"
          , { package = "elm-lang/core"
            , version = "1.0.0"
            , moduleName = "Platform.Cmd"
            , symbols = [ "!", "map" ]
            }
          )
        , ( "Platform.Sub"
          , { package = "elm-lang/core"
            , version = "1.0.0"
            , moduleName = "Platform.Sub"
            , symbols = [ "map" ]
            }
          )
        ]


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
        |> Dict.union defaultModules


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


defaultImport : List Statement
defaultImport =
    crashableParse """
test =
    let
        list = 1 :: []
        head = List.head list
        check = 1 == 2
        value = Maybe.withDefault (Just "hello") "default"
        result = Result.withDefault 0 (String.toInt "123")
        first = Tuple.first (0, 0)
        fn = Platform.sendToApp
        fn2 = Platform.Cmd.map
        fn3 = Platform.Sub.map
    in
        Debug.log "test" Nothing
"""


basicTest : Test
basicTest =
    let
        result =
            [ { package = "elm-lang/html"
              , moduleName = "Html"
              , symbol = "text"
              , version = "1.0.0"
              , line = 4
              , column = 6
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
            , test "defaultImport" <|
                \_ ->
                    Expect.equal (Parser.getReferences basicModules defaultImport)
                        [ { package = "elm-lang/core", moduleName = "List", symbol = "::", version = "1.0.0", line = 3, column = 18 }
                        , { package = "elm-lang/core", moduleName = "List", symbol = "head", version = "1.0.0", line = 4, column = 14 }
                        , { package = "elm-lang/core", moduleName = "Basics", symbol = "==", version = "1.0.0", line = 5, column = 19 }
                        , { package = "elm-lang/core", moduleName = "Maybe", symbol = "withDefault", version = "1.0.0", line = 6, column = 15 }
                        , { package = "elm-lang/core", moduleName = "Result", symbol = "withDefault", version = "1.0.0", line = 7, column = 16 }
                        , { package = "elm-lang/core", moduleName = "String", symbol = "toInt", version = "1.0.0", line = 7, column = 38 }
                        , { package = "elm-lang/core", moduleName = "Tuple", symbol = "first", version = "1.0.0", line = 8, column = 15 }
                        , { package = "elm-lang/core", moduleName = "Platform", symbol = "sendToApp", version = "1.0.0", line = 9, column = 12 }
                        , { package = "elm-lang/core", moduleName = "Platform.Cmd", symbol = "map", version = "1.0.0", line = 10, column = 13 }
                        , { package = "elm-lang/core", moduleName = "Platform.Sub", symbol = "map", version = "1.0.0", line = 11, column = 13 }
                        , { package = "elm-lang/core", moduleName = "Debug", symbol = "log", version = "1.0.0", line = 13, column = 7 }
                        ]
            ]



-- modules --


regularModule : List Statement
regularModule =
    crashableParse """
module Foo exposing (main)

main = Debug.log "test"
"""


portModule : List Statement
portModule =
    crashableParse """
port module Foo exposing (main)

main = Debug.log "test"
"""


effectModule : List Statement
effectModule =
    crashableParse """
module Foo exposing (main)

main = Debug.log "test"
"""


modulesTest : Test
modulesTest =
    let
        result =
            [ { package = "elm-lang/core"
              , moduleName = "Debug"
              , symbol = "log"
              , version = "1.0.0"
              , line = 3
              , column = 6
              }
            ]
    in
        describe "getReferences should deal with different module types"
            [ test "regularModule" <|
                \_ ->
                    Expect.equal (Parser.getReferences basicModules regularModule) result
            , test "portModule" <|
                \_ ->
                    Expect.equal (Parser.getReferences basicModules portModule) result
            , test "effectModule" <|
                \_ ->
                    Expect.equal (Parser.getReferences basicModules effectModule) result
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
        |> Dict.union defaultModules


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
                    [ { package = "elm-lang/html", moduleName = "Html", symbol = "beginnerProgram", version = "1.0.0", line = 5, column = 1 }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "div", version = "1.0.0", line = 30, column = 1 }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "button", version = "1.0.0", line = 31, column = 5 }
                    , { package = "elm-lang/html", moduleName = "Html.Events", symbol = "onClick", version = "2.0.0", line = 31, column = 14 }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "text", version = "1.0.0", line = 31, column = 36 }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "div", version = "1.0.0", line = 32, column = 5 }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "text", version = "1.0.0", line = 32, column = 14 }
                    , { package = "elm-lang/core", moduleName = "Basics", symbol = "toString", version = "1.0.0", line = 32, column = 20 }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "button", version = "1.0.0", line = 33, column = 5 }
                    , { package = "elm-lang/html", moduleName = "Html.Events", symbol = "onClick", version = "2.0.0", line = 33, column = 14 }
                    , { package = "elm-lang/html", moduleName = "Html", symbol = "text", version = "1.0.0", line = 33, column = 36 }
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
