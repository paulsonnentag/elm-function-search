module Request exposing (searchAll, SearchAllResult, Symbol, Package)

import Http
import HttpBuilder exposing (withQueryParams, withExpectJson, toRequest)
import Json.Decode as Decode exposing (Decoder, string, field, list)


type alias Symbol =
    { name : String
    , module_ : String
    , package : String
    }


type alias Package =
    { name : String
    }


type alias SearchAllResult =
    { symbols : List Symbol
    , packages : List Package
    }


apiUrl : String
apiUrl =
    "http://localhost:3000"


searchAll : String -> Http.Request SearchAllResult
searchAll name =
    HttpBuilder.get (apiUrl ++ "/search/all")
        |> withQueryParams [ ( "name", name ) ]
        |> withExpectJson allResponseDecoder
        |> toRequest


symbol : Decoder Symbol
symbol =
    Decode.map3 Symbol
        (field "name" string)
        (field "module" string)
        (field "package" string)


package : Decoder Package
package =
    Decode.map Package
        (field "name" string)


allResponseDecoder : Decoder SearchAllResult
allResponseDecoder =
    Decode.map2 SearchAllResult
        (field "symbols" (list symbol))
        (field "packages" (list package))
