module Main exposing (..)

import Http
import Time
import HttpBuilder exposing (withQueryParams, withExpectJson, withTimeout, toRequest)
import Json.Decode as Decode exposing (Decoder, string, field, list, bool)
import Style
import Element.Attributes exposing (attribute, padding, paddingBottom, spacing, vary)
import Element exposing (Element, h1, el, column, text)
import Element.Events exposing (onClick, on, keyCode)
import Element.Input as Input
import Style.Font as Font
import Style.Color as Color
import Style.Border as Border
import Html exposing (Html)
import Style.Scale as Scale
import Color
import ListSelection exposing (ListSelection)


---- MODEL ----


type RemoteData data
    = Loading
    | Failed String
    | Success data


type Model
    = Search SearchModel
    | Examples ExamplesModel


type alias SearchModel =
    { query : String
    , result : RemoteData (ListSelection Symbol)
    }


type alias ExamplesModel =
    { package : String
    , module_ : String
    , symbol : String
    }


initialModel : Model
initialModel =
    Search { query = "", result = Success (ListSelection.fromList []) }


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
    | KeyPressed KeyAction


type KeyAction
    = Prev
    | Next
    | Select
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeQuery query ->
            ( Search { query = query, result = Loading }
            , Http.send LoadMatches (searchRequest query)
            )

        _ ->
            case model of
                Search model ->
                    case msg of
                        LoadMatches result ->
                            case result of
                                Err err ->
                                    ( Search { model | result = (Failed (toString err)) }, Cmd.none )

                                Ok matches ->
                                    ( Search { model | result = (Success (ListSelection.fromList matches)) }, Cmd.none )

                        LoadExamples symbol ->
                            ( Examples
                                { package = symbol.package
                                , module_ = symbol.module_
                                , symbol = symbol.name
                                }
                            , Cmd.none
                            )

                        KeyPressed keyAction ->
                            case model.result of
                                Success selection ->
                                    case keyAction of
                                        Next ->
                                            ( Search
                                                { model
                                                    | result = Success (ListSelection.next selection)
                                                }
                                            , Cmd.none
                                            )

                                        Prev ->
                                            -- UP
                                            ( Search
                                                { model
                                                    | result = Success (ListSelection.prev selection)
                                                }
                                            , Cmd.none
                                            )

                                        Select ->
                                            case ListSelection.getSelectedItem selection of
                                                Nothing ->
                                                    ( Search model, Cmd.none )

                                                Just symbol ->
                                                    ( Examples
                                                        { package = symbol.package
                                                        , module_ = symbol.module_
                                                        , symbol = symbol.name
                                                        }
                                                    , Cmd.none
                                                    )

                                        NoOp ->
                                            ( Search model, Cmd.none )

                                _ ->
                                    ( Search model, Cmd.none )

                        _ ->
                            ( Search model, Cmd.none )

                Examples model ->
                    ( Examples model, Cmd.none )



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


type Variation
    = Selected


scale : Int -> Float
scale =
    Scale.modular 16 1.3


stylesheet : Style.StyleSheet Styles Variation
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
            , Style.hover
                [ Color.background Color.lightBlue
                ]
            , Style.variation Selected
                [ Color.background Color.lightBlue ]
            ]
        , Style.style ResultItemSymbol
            [ Font.size (scale 2)
            ]
        , Style.style ResultItemPackage
            [ Color.text (Color.rgb 50 50 50) ]
        , Style.style None []
        , Style.style ResultItems []
        ]



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

                --, on "keyup" (Decode.map KeyPressed decodeKey)
                ]
                { onChange = ChangeQuery
                , value = "123" -- (queryValue model)
                , label =
                    Input.placeholder
                        { label = Input.labelLeft (el None [ attribute "style" "display:none;" ] (text "Search"))
                        , text = "Try List.map or elm-lang/Http"
                        }
                , options = []
                }
            , case model of
                Search { query, result } ->
                    case result of
                        Failed err ->
                            text err

                        Success selection ->
                            let
                                items =
                                    ListSelection.getItems selection

                                selectedItem =
                                    ListSelection.getSelectedItem selection
                            in
                                column ResultItems
                                    []
                                    (List.map (resultItemView selectedItem) items)

                        Loading ->
                            text "loading ..."

                Examples { package, module_, symbol } ->
                    text ((queryValue model))
            ]


decodeKey : Decoder KeyAction
decodeKey =
    Decode.map2
        (\key withCtrl ->
            case ( key, withCtrl ) of
                ( "ArrowUp", _ ) ->
                    Prev

                ( "ArrowDown", _ ) ->
                    Next

                ( "Enter", _ ) ->
                    Select

                ( "p", true ) ->
                    Prev

                ( "n", true ) ->
                    Next

                _ ->
                    NoOp
        )
        (field "key" string)
        (field "ctrlKey" bool)


resultItemView : Maybe Symbol -> Symbol -> Element Styles Variation Msg
resultItemView selectedSymbol symbol =
    column ResultItem
        [ onClick (LoadExamples symbol)
        , padding 5
        , vary Selected (Just symbol == selectedSymbol)
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
