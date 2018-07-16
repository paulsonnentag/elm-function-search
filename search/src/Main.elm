module Main exposing (..)

import Http
import Time
import HttpBuilder exposing (withQueryParams, withExpectJson, withTimeout, toRequest)
import Json.Decode as Decode exposing (Decoder, string, field, list)
import Style
import Element.Attributes exposing (attribute, padding, paddingBottom, spacing)
import Element exposing (Element, h1, el, column, text)
import Element.Events exposing (onClick)
import Element.Input as Input
import Style.Font as Font
import Style.Color as Color
import Style.Border as Border
import Html exposing (Html)
import Style.Scale as Scale
import Color


--- STYLES ---


type Styles
    = App
    | Title
    | SearchInput
    | ResultItems
    | ResultItem
    | ResultItemSymbol
    | ResultItemPackage
    | None


scale : Int -> Float
scale =
    Scale.modular 16 1.3


stylesheet : Style.StyleSheet Styles variation
stylesheet =
    Style.styleSheet
        [ Style.style App
            [ Font.typeface [ Font.sansSerif ]
            , Font.size (scale 1)
            ]
        , Style.style Title
            [ Font.size (scale 3) ]
        , Style.style SearchInput
            [ Font.size (scale 2)
            , Border.all 1
            , Color.border Color.black
            ]
        , Style.style ResultItem
            [ Border.left 1
            , Border.right 1
            , Border.bottom 1
            , Color.border Color.black
            ]
        , Style.style ResultItemSymbol
            [ Font.size (scale 2)
            ]
        , Style.style ResultItemPackage
            [ Color.text (Color.rgb 50 50 50) ]
        , Style.style None []
        , Style.style ResultItems []
        ]



---- MODEL ----


type RemoteData data
    = Loading
    | Failed String
    | Success data


type alias Matches =
    RemoteData (List Symbol)


type Model
    = Search SearchModel
    | Examples ExamplesModel


type alias SearchModel =
    { query : String
    , matches : Matches
    }


type alias ExamplesModel =
    { package : String
    , module_ : String
    , symbol : String
    }


initialModel : Model
initialModel =
    Search { query = "", matches = Success [] }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )


searchRequest : String -> Http.Request (List Symbol)
searchRequest search =
    HttpBuilder.get "http://localhost:3000/symbols"
        |> withQueryParams [ ( "query", search ) ]
        |> withTimeout (Time.second * 2)
        |> withExpectJson (list symbol)
        |> toRequest


type alias Symbol =
    { name : String
    , module_ : String
    , package : String
    }


symbol : Decoder Symbol
symbol =
    Decode.map3 Symbol
        (field "name" string)
        (field "module" string)
        (field "package" string)



---- UPDATE ----


type Msg
    = ChangeQuery String
    | LoadMatches (Result Http.Error (List Symbol))
    | LoadExamples Symbol


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeQuery query ->
            ( Search { query = query, matches = Loading }
            , Http.send LoadMatches (searchRequest query)
            )

        _ ->
            case model of
                Search model ->
                    case msg of
                        LoadMatches result ->
                            case result of
                                Err err ->
                                    ( Search { model | matches = (Failed (toString err)) }, Cmd.none )

                                Ok matches ->
                                    ( Search { model | matches = (Success matches) }, Cmd.none )

                        LoadExamples symbol ->
                            ( Examples
                                { package = symbol.package
                                , module_ = symbol.module_
                                , symbol = symbol.name
                                }
                            , Cmd.none
                            )

                        _ ->
                            ( Search model, Cmd.none )

                Examples model ->
                    ( Examples model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    Element.layout stylesheet <|
        column App
            [ padding (scale 3) ]
            [ h1 Title [ paddingBottom (scale 2) ] (text "Elm function search")
            , Input.text SearchInput
                [ attribute "autofocus" ""
                , padding 5
                ]
                { onChange = ChangeQuery
                , value = (queryValue model)
                , label =
                    Input.placeholder
                        { label = Input.labelLeft (el None [ attribute "style" "display:none;" ] (text "Search"))
                        , text = "Try List.map or elm-lang/Http"
                        }
                , options = []
                }
            , case model of
                Search { query, matches } ->
                    case matches of
                        Failed err ->
                            text err

                        Success symbols ->
                            column ResultItems
                                []
                                (List.map resultItemView symbols)

                        Loading ->
                            text "loading ..."

                _ ->
                    text "todo add examples"
            ]


resultItemView : Symbol -> Element Styles variation Msg
resultItemView symbol =
    column ResultItem
        [ onClick (LoadExamples symbol)
        , padding 5
        ]
        [ el ResultItemPackage [] (text symbol.package)
        , el ResultItemSymbol [] (text (symbol.module_ ++ "." ++ symbol.name))
        ]


queryValue : Model -> String
queryValue model =
    case model of
        Search { query } ->
            query

        Examples { package, module_, symbol } ->
            package ++ "/" ++ module_ ++ "." ++ symbol



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
