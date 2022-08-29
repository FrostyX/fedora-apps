module Main exposing (..)

import AppGraph
import Browser
import Decoders exposing (..)
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Http
import Models exposing (..)


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    Apps


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch []


init : () -> ( Model, Cmd Msg )
init _ =
    ( Apps [], Cmd.batch [ readApps ] )


type Msg
    = Increment
    | Decrement
    | GotApps (Result Http.Error Apps)


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
        Increment ->
            ( Apps [], Cmd.none )

        Decrement ->
            ( Apps [], Cmd.none )

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


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , div [] [ text (String.fromInt 1) ]
        , button [ onClick Increment ] [ text "+" ]
        ]
