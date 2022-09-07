module Logic exposing (..)

import Decoders exposing (..)
import Dict exposing (Dict)
import Graph exposing (Graph)
import Http
import Models exposing (..)
import Simple.Fuzzy as Fuzzy


appIcon : App -> String
appIcon app =
    "/img/icons/"
        ++ (if String.isEmpty app.data.icon then
                "missing.png"

            else
                app.data.icon
           )


readApps : Cmd Msg
readApps =
    Http.get
        -- https://onlineyamltools.com/convert-yaml-to-json
        { url = "/data/apps.json"
        , expect = Http.expectJson GotApps appListDecoder
        }


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
    Fuzzy.match value name |> not


graphData : Apps -> Graph String ()
graphData apps =
    let
        appNames =
            case apps of
                Apps apps2 ->
                    case List.head apps2 of
                        Just root ->
                            appsToList root

                        Nothing ->
                            []

        appIds =
            Dict.fromList (List.indexedMap (\k v -> ( v, k )) appNames)

        edges =
            case apps of
                Apps apps2 ->
                    case List.head apps2 of
                        Just root ->
                            graphEdges root appIds

                        Nothing ->
                            []
    in
    Graph.fromNodeLabelsAndEdgePairs
        appNames
        edges


graphEdges : App -> Dict String Int -> List ( Int, Int )
graphEdges appRoot appIds =
    let
        log =
            Debug.log "appIds" appIds
    in
    case appRoot.children of
        Apps apps ->
            (apps
                |> List.map (\c -> c.name)
                |> List.map (\c -> ( appRoot.name, c ))
                |> List.map
                    (\t ->
                        ( Dict.get (Tuple.first t) appIds
                            |> Maybe.withDefault -1
                        , Dict.get (Tuple.second t) appIds
                            |> Maybe.withDefault -1
                        )
                    )
            )
                ++ (List.map (\x -> graphEdges x appIds) apps
                        |> List.concat
                   )
