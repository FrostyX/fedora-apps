module Main exposing (..)

import AppGraph
import Bootstrap.Popover as Popover
import Browser
import Debug
import Decoders exposing (..)
import Dict exposing (Dict)
import Http
import Models exposing (..)
import Set exposing (Set)
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
      , hiddenApps = Set.empty

      -- , hiddenApps = Set.fromList [ "FedoraPeople", "Fedora Accounts" ]
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

        Search value ->
            if String.isEmpty value then
                ( { model | hiddenApps = Set.empty }, Cmd.none )

            else
                case model.apps of
                    Apps apps ->
                        case List.head apps of
                            Just app ->
                                ( { model
                                    | hiddenApps =
                                        appsToList app
                                            |> List.filter (appFilter value)
                                            |> Set.fromList
                                  }
                                , Cmd.none
                                )

                            Nothing ->
                                ( { model | apps = model.apps }, Cmd.none )


appsToList : App -> List String
appsToList appRoot =
    case appRoot.children of
        Apps apps ->
            [ appRoot.name ]
                ++ (apps
                        |> List.map appsToList
                        |> List.concat
                   )


appFilter : String -> String -> Bool
appFilter value name =
    name /= value
