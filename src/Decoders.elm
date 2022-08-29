module Decoders exposing (..)

-- Recursive JSON tree:
-- https://korban.net/posts/elm/2018-04-13-decoding-recursive-json-in-elm/

import Json.Decode
    exposing
        ( Decoder
        , lazy
        , list
        , map
        , string
        , succeed
        )
import Json.Decode.Pipeline exposing (..)


type alias App =
    { name : String
    , children : Apps
    }


type Apps
    = Apps (List App)


appDecoder : Decoder App
appDecoder =
    succeed App
        |> required "name" string
        |> optional "children" (lazy (\_ -> appListDecoder)) (Apps [])


appListDecoder : Decoder Apps
appListDecoder =
    map Apps <| list (lazy (\_ -> appDecoder))
