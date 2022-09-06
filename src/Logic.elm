module Logic exposing (..)

import Decoders exposing (..)
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
    in
    Graph.fromNodeLabelsAndEdgePairs
        appNames
        [ ( 0, 1 )
        , ( 0, 2 )
        , ( 0, 3 )
        , ( 0, 4 )
        , ( 0, 5 )
        , ( 0, 6 )
        , ( 0, 7 )
        , ( 0, 8 )

        --
        , ( 3, 9 )
        , ( 3, 10 )
        , ( 3, 11 )
        ]
