module Logic exposing (..)

import Decoders exposing (..)
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
