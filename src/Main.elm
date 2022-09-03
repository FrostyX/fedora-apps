module Main exposing (..)

import AppGraph
import Bootstrap.Popover as Popover
import Browser
import Debug
import Decoders exposing (..)
import Dict exposing (Dict)
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
    ( { apps = Apps []
      , popoverState = Dict.fromList []
      }
    , Cmd.batch [ readApps ]
    )


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
                    ( { model | apps = apps }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        PopoverMsg app state ->
            ( { model
                | popoverState =
                    Dict.update app.name (\_ -> Just state) model.popoverState
              }
            , Cmd.none
            )
