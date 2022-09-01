module Main exposing (..)

import AppGraph
import Browser
import Decoders exposing (..)
import Http
import Models exposing (..)
import Views exposing (view)


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch []


init : () -> ( Model, Cmd Msg )
init _ =
    ( Apps [], Cmd.batch [ readApps ] )


readApps : Cmd Msg
readApps =
    Http.get
        -- https://onlineyamltools.com/convert-yaml-to-json
        { url = "/data/apps.json"
        , expect = Http.expectJson GotApps appListDecoder
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotApps result ->
            let
                log =
                    Debug.log "Result" result
            in
            case result of
                Ok apps ->
                    ( apps, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )
