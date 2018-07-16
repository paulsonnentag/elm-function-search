module Main exposing (..)

import Html exposing (Html, div, text, ul, li, input)
import Html.Attributes exposing (src, value, placeholder, style)
import Html.Events exposing (onInput, onClick)
import Http
import Time
import HttpBuilder exposing (withQueryParams, withExpectJson, withTimeout, toRequest)
import Json.Decode as Decode exposing (Decoder, string, field, list)


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
    div []
        [ input
            [ onInput ChangeQuery
            , value (queryValue model)
            , placeholder "try elm-lang/core or List.map"
            , style [ ( "width", "100%" ), ( "font-size", "20px" ) ]
            ]
            []
        , case model of
            Search { query, matches } ->
                div []
                    [ case matches of
                        Failed err ->
                            text err

                        Success symbols ->
                            ul []
                                (List.map
                                    (\symbol ->
                                        li [ onClick (LoadExamples symbol) ]
                                            [ (text (symbol.module_ ++ "." ++ symbol.name ++ " (" ++ symbol.package ++ ")")) ]
                                    )
                                    symbols
                                )

                        Loading ->
                            text "loading ..."
                    ]

            _ ->
                text "todo add examples"
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
