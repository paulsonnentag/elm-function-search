port module Main exposing (main)

import Parser exposing (Module, Modules, Reference)
import Platform
import Platform.Sub as Sub
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


port outputPort : Encode.Value -> Cmd msg


port inputPort : (Decode.Value -> msg) -> Sub msg


type OutputMessage
    = ParseFileResponse String (Result (List String) (List Reference))


encodeOutputMessage : OutputMessage -> Encode.Value
encodeOutputMessage msg =
    case msg of
        ParseFileResponse requestId result ->
            Encode.object
                ([ ( "requestId", Encode.string requestId )
                 ]
                    ++ case result of
                        Ok references ->
                            [ ( "type", Encode.string "success" )
                            , ( "data"
                              , Encode.object
                                    [ ( "results", Encode.list (List.map encodeReference references) )
                                    ]
                              )
                            ]

                        Err errors ->
                            [ ( "type", Encode.string "error" )
                            , ( "data"
                              , Encode.object
                                    [ ( "errors", Encode.list (List.map Encode.string errors) )
                                    ]
                              )
                            ]
                )


encodeReference : Reference -> Encode.Value
encodeReference { package, moduleName, symbol, version, column, line } =
    Encode.object
        [ ( "package", Encode.string package )
        , ( "module", Encode.string moduleName )
        , ( "symbol", Encode.string symbol )
        , ( "version", Encode.string version )
        , ( "colum", Encode.int column )
        , ( "line", Encode.int line )
        ]


type alias Model =
    {}


init : ( Model, Cmd msg )
init =
    ( {}, Cmd.none )


type Msg
    = ParseFileRequest String Modules String
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ParseFileRequest requestId modules source ->
            let
                result =
                    Parser.parseReferences modules source
            in
                ( model, outputPort (encodeOutputMessage (ParseFileResponse requestId result)) )

        NoOp ->
            ( model, Cmd.none )


main : Program Never Model Msg
main =
    Platform.program
        { init = init
        , update = update
        , subscriptions =
            (\_ -> inputPort (decodeInputMessage))
        }


decodeInputMessage : Decode.Value -> Msg
decodeInputMessage value =
    case Decode.decodeValue inputMessageDecoder value of
        Ok msg ->
            msg

        Err err ->
            Debug.log ("couldn't decode message " ++ err) NoOp


inputMessageDecoder : Decoder Msg
inputMessageDecoder =
    Decode.map3 ParseFileRequest
        (Decode.field "requestId" Decode.string)
        (Decode.field "modules" (Decode.dict moduleDecoder))
        (Decode.field "source" Decode.string)


moduleDecoder : Decoder Module
moduleDecoder =
    Decode.map4 Module
        (Decode.field "version" Decode.string)
        (Decode.field "package" Decode.string)
        (Decode.field "moduleName" Decode.string)
        (Decode.field "symbols" (Decode.list Decode.string))
