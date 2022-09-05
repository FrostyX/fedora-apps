module Main exposing (..)

import AppGraph
import Bootstrap.Popover as Popover
import Browser
import Debug
import Dict exposing (Dict)
import Logic exposing (..)
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
