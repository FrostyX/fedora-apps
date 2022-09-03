module Models exposing (..)

import Bootstrap.Popover as Popover
import Dict exposing (Dict)
import Http


type alias Model =
    { apps : Apps
    , popoverState : Dict String Popover.State
    }


type Msg
    = GotApps (Result Http.Error Apps)
    | PopoverMsg App Popover.State
    | Search String


type alias App =
    { name : String
    , data : AppData
    , children : Apps
    }


type alias AppData =
    { description : String
    , url : String
    , bugs_url : String
    , docs_url : String
    , icon : String
    }


type Apps
    = Apps (List App)
