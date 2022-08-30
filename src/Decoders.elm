module Decoders exposing (..)

-- Recursive JSON tree:
-- https://korban.net/posts/elm/2018-04-13-decoding-recursive-json-in-elm/

import Json.Decode
    exposing
        ( Decoder
        , field
        , lazy
        , list
        , map
        , map2
        , map3
        , string
        , succeed
        )
import Json.Decode.Pipeline exposing (..)
import Models exposing (..)


appDecoder : Decoder App
appDecoder =
    succeed App
        |> required "name" string
        |> required "data" appDataDecoder
        |> optional "children" (lazy (\_ -> appListDecoder)) (Apps [])


appListDecoder : Decoder Apps
appListDecoder =
    map Apps <| list (lazy (\_ -> appDecoder))


appDataDecoder : Decoder AppData
appDataDecoder =
    succeed AppData
        |> required "description" string
        |> optional "url" string ""
