module Models exposing (..)

import Bootstrap.Popover as Popover
import Browser.Dom as Dom
import Dict exposing (Dict)
import Force
import Graph exposing (Edge, Graph, Node, NodeContext, NodeId)
import Http
import Set exposing (Set)
import Time
import Zoom exposing (OnZoom, Zoom)


type alias Model =
    { apps : Apps
    , hiddenApps : Set String
    , popoverState : Dict String Popover.State
    , graphReady : GraphReady
    }


type Msg
    = GotApps (Result Http.Error Apps)
    | PopoverMsg App Popover.State
    | Search String
      -- | AppGraphMsg AppGraphMsg
      -- Graph
    | ReceiveElementPosition (Result Dom.Error Dom.Element)
    | Resize Int Int
    | Tick Time.Posix
    | ZoomMsg OnZoom


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



-- Graph


type GraphReady
    = Init (Graph Entity ())
    | Ready ReadyState
    | NotYet


type alias ReadyState =
    { graph : Graph Entity ()
    , simulation : Force.State NodeId
    , zoom : Zoom

    -- The position and dimensions of the svg element.
    , element : Element

    -- If you immediately show the graph when moving from `Init` to `Ready`,
    -- you will briefly see the nodes in the upper left corner before the first
    -- simulation tick positions them in the center. To avoid this sudden jump,
    -- `showGraph` is initialized with `False` and set to `True` with the first
    -- `Tick`.
    , showGraph : Bool
    }


type alias Element =
    { height : Float
    , width : Float
    , x : Float
    , y : Float
    }


type alias Entity =
    Force.Entity NodeId { value : String }
