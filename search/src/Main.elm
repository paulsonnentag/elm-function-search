module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (src, value, placeholder)
import Html.Events exposing (onInput)
import Http
import Request exposing (SearchAllResult, Package, Symbol)


---- MODEL ----


type Model
    = Start StartModel
    | Module ModuleModel
    | Function FunctionModel


type RemoteData data
    = Loading
    | Failed String
    | Success data


type alias StartModel =
    { search : String
    , matches : Maybe (RemoteData SearchAllResult)
    }


type alias FunctionModel =
    { search : String
    , module_ : Module
    , function : Function
    , examples : RemoteData (List String)
    }


type alias ModuleModel =
    { search : String
    , module_ : Module
    , functions : RemoteData (List Function)
    }


type alias Module =
    String


type alias Function =
    String


initialModel : Model
initialModel =
    Start { search = "", matches = Nothing }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



---- UPDATE ----


type Msg
    = UpdateSearch String
    | LoadSearchAll (Result Http.Error SearchAllResult)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        Start startModel ->
            case msg of
                UpdateSearch search ->
                    if search == "" then
                        ( Start { startModel | search = "", matches = Nothing }, Cmd.none )
                    else
                        ( Start { startModel | search = search }, Http.send LoadSearchAll (Request.searchAll search) )

                LoadSearchAll result ->
                    case result of
                        Err err ->
                            ( Start { startModel | matches = Just (Failed (toString err)) }, Cmd.none )

                        Ok matches ->
                            ( Start { startModel | matches = Just (Success matches) }, Cmd.none )

        _ ->
            ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    case model of
        Start { search, matches } ->
            div []
                [ input
                    [ onInput UpdateSearch
                    , value search
                    , placeholder "try elm-lang/core or List.map"
                    ]
                    []
                , case matches of
                    Nothing ->
                        text "enter something"

                    Just result ->
                        case result of
                            Failed err ->
                                text err

                            Success { symbols, packages } ->
                                div []
                                    [ h1 [] [ text "packages" ]
                                    , ul []
                                        (List.map (\p -> li [] [ text p.name ]) packages)
                                    , h1 [] [ text "symbols" ]
                                    , ul []
                                        (List.map (\s -> li [] [ (text (s.module_ ++ "." ++ s.name ++ " (" ++ s.package ++ ")")) ]) symbols)
                                    ]

                            Loading ->
                                text "loading ..."
                ]

        _ ->
            text "not implemented"



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
