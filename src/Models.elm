module Models exposing (..)

import Http


type alias Model =
    Apps


type Msg
    = GotApps (Result Http.Error Apps)


type alias App =
    { name : String
    , data : AppData
    , children : Apps
    }


type alias AppData =
    { description : String
    , url : String
    }


type Apps
    = Apps (List App)
