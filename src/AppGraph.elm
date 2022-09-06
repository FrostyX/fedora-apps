-- module ForceDirectedGraphWithZoom exposing (main)


module AppGraph exposing (..)

import Browser
import Browser.Dom as Dom
import Browser.Events as Events
import Color
import Dict exposing (Dict)
import Force
import Graph exposing (Edge, Graph, Node, NodeContext, NodeId)
import Html exposing (div)
import Html.Attributes exposing (style)
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as Decode
import Models exposing (..)
import Set exposing (Set)
import Task
import Time
import TypedSvg exposing (circle, defs, g, line, marker, polygon, rect, svg, text_, title)
import TypedSvg.Attributes as Attrs exposing (class, cursor, fill, fontSize, id, markerEnd, markerHeight, markerWidth, orient, pointerEvents, points, refX, refY, stroke, transform)
import TypedSvg.Attributes.InPx exposing (cx, cy, dx, dy, height, r, strokeWidth, width, x1, x2, y1, y2)
import TypedSvg.Core exposing (Attribute, Svg, text)
import TypedSvg.Types exposing (AlignmentBaseline(..), AnchorAlignment(..), Cursor(..), Length(..), Opacity(..), Paint(..), Transform(..))
import Zoom exposing (OnZoom, Zoom)



-- Constants


elementId : String
elementId =
    "exercise-graph"


edgeColor : Paint
edgeColor =
    Paint <| Color.rgb255 180 180 180



-- Init


{-| We initialize the graph here, but we don't start the simulation yet, because
we first need the position and dimensions of the svg element to calculate the
correct node positions and the center force.
-}
init : () -> ( Model, Cmd Msg )
init _ =
    let
        result : ( GraphReady, Cmd Msg )
        result =
            graphInit graphData
    in
    ( { apps = Apps []
      , hiddenApps = Set.empty

      -- , hiddenApps = Set.fromList [ "FedoraPeople", "Fedora Accounts" ]
      , popoverState = Dict.fromList []
      , graphReady = Tuple.first result
      }
    , Tuple.second result
    )


graphInit : Graph String () -> ( GraphReady, Cmd Msg )
graphInit data =
    let
        graph : Graph Entity ()
        graph =
            Graph.mapContexts initNode data
    in
    ( Init graph, getElementPosition )


{-| The graph data we defined at the end of the module has the type
`Graph String ()`. We have to convert it into a `Graph Entity ()`.
`Force.Entity` is an extensible record which includes the coordinates for the
node.
-}
initNode : NodeContext String () -> NodeContext Entity ()
initNode ctx =
    { node =
        { label = Force.entity ctx.node.id ctx.node.label
        , id = ctx.node.id
        }
    , incoming = ctx.incoming
    , outgoing = ctx.outgoing
    }


{-| Initializes the simulation by setting the forces for the graph.
-}
initSimulation : Graph Entity () -> Float -> Float -> Force.State NodeId
initSimulation graph width height =
    let
        link : { c | from : a, to : b } -> ( a, b )
        link { from, to } =
            ( from, to )
    in
    Force.simulation
        [ -- Defines the force that pulls connected nodes together. You can use
          -- `Force.customLinks` if you need to adjust the distance and
          -- strength.
          Force.customLinks 1
            (Graph.edges graph
                |> List.map link
                |> List.map
                    (\x ->
                        { distance = 100
                        , source = Tuple.first x
                        , strength = Just 2
                        , target = Tuple.second x
                        }
                    )
            )

        -- Defines the force that pushes the nodes apart. The default strength
        -- is `-30`, but since we are drawing fairly large circles for each
        -- node, we need to increase the repulsion by decreasing the strength to
        -- `-150`.
        , Force.manyBodyStrength -150 <| List.map .id <| Graph.nodes graph
        , Force.collision 21 <| List.map .id <| Graph.nodes graph

        -- Defines the force that pulls nodes to a center. We set the center
        -- coordinates to the center of the svg viewport.
        , Force.center (width / 2) (height / 2)
        ]
        |> Force.iterations 100


{-| Initializes the zoom and sets a minimum and maximum zoom level.

You can also use `Zoom.translateExtent` to restrict the area in which the user
may drag, but since the graph is larger than the viewport and the exact
dimensions depend on the data and the final layout, you would either need to use
some kind of heuristic for the final dimensions here, or you would have to let
the simulation play out (or use `Force.computeSimulate` to calculate it at
once), find the min and max x and y positions of the graph nodes and use those
values to set the translate extent.

-}
initZoom : Element -> Zoom
initZoom element =
    Zoom.init { width = element.width, height = element.height }
        |> Zoom.scaleExtent 0.1 2



-- Subscriptions


{-| We have three groups of subscriptions:

1.  Mouse events, to handle mouse interaction with the nodes.
2.  A subscription on the animation frame, to trigger simulation ticks.
3.  Browser resizes, to update the zoom state and the position of the nodes
    when the size and position of the svg viewport change.

We want to make sure that we only subscribe to mouse events while there is
a mouse interaction in progress, and that we only subscribe to
`Browser.Events.onAnimationFrame` while the simulation is in progress.

-}
subscriptions : Model -> Sub Msg
subscriptions model =
    graphSubscriptions model.graphReady


graphSubscriptions : GraphReady -> Sub Msg
graphSubscriptions graphReady =
    let
        readySubscriptions : ReadyState -> Sub Msg
        readySubscriptions { simulation, zoom } =
            Sub.batch
                [ Zoom.subscriptions zoom ZoomMsg
                , if Force.isCompleted simulation then
                    Sub.none

                  else
                    Events.onAnimationFrame Tick
                ]
    in
    Sub.batch
        [ case graphReady of
            NotYet ->
                Sub.none

            Init _ ->
                Sub.none

            Ready state ->
                readySubscriptions state
        , Events.onResize Resize
        ]



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        result : ( GraphReady, Cmd Msg )
        result =
            graphUpdate msg model.graphReady
    in
    ( { model | graphReady = Tuple.first result }, Tuple.second result )


graphUpdate : Msg -> GraphReady -> ( GraphReady, Cmd Msg )
graphUpdate msg graphReady =
    let
        log =
            Debug.log "Update" msg
    in
    case ( msg, graphReady ) of
        ( Tick _, Ready state ) ->
            handleTick state

        ( Tick _, Init _ ) ->
            ( graphReady, Cmd.none )

        ( ReceiveElementPosition (Ok { element }), Init graph ) ->
            -- When we get the svg element position and dimensions, we are
            -- ready to initialize the simulation and the zoom, but we cannot
            -- show the graph yet. If we did, we would see a noticable jump.
            ( Ready
                { element = element
                , graph = graph
                , showGraph = False
                , simulation =
                    initSimulation
                        graph
                        element.width
                        element.height
                , zoom = initZoom element
                }
            , Cmd.none
            )

        ( ReceiveElementPosition (Ok { element }), Ready state ) ->
            ( Ready
                { element = element
                , graph = state.graph
                , showGraph = True
                , simulation =
                    initSimulation
                        state.graph
                        element.width
                        element.height
                , zoom = initZoom element
                }
            , Cmd.none
            )

        ( ReceiveElementPosition (Err _), _ ) ->
            ( graphReady, Cmd.none )

        ( Resize _ _, _ ) ->
            ( graphReady, getElementPosition )

        ( ZoomMsg zoomMsg, Ready state ) ->
            ( Ready
                { state
                    | zoom = Zoom.update zoomMsg state.zoom
                }
            , Cmd.none
            )

        ( ZoomMsg _, Init _ ) ->
            ( graphReady, Cmd.none )

        _ ->
            ( graphReady, Cmd.none )


handleTick : ReadyState -> ( GraphReady, Cmd Msg )
handleTick state =
    let
        ( newSimulation, list ) =
            Force.tick state.simulation <|
                List.map .label <|
                    Graph.nodes state.graph
    in
    ( Ready
        { state
            | graph = updateGraphWithList state.graph list
            , showGraph = True
            , simulation = newSimulation
        }
    , Cmd.none
    )


updateNode :
    ( Float, Float )
    -> NodeContext Entity ()
    -> NodeContext Entity ()
updateNode ( x, y ) nodeCtx =
    let
        nodeValue =
            nodeCtx.node.label
    in
    updateContextWithValue nodeCtx { nodeValue | x = x, y = y }


updateContextWithValue :
    NodeContext Entity ()
    -> Entity
    -> NodeContext Entity ()
updateContextWithValue nodeCtx value =
    let
        node =
            nodeCtx.node
    in
    { nodeCtx | node = { node | label = value } }


updateGraphWithList : Graph Entity () -> List Entity -> Graph Entity ()
updateGraphWithList =
    let
        graphUpdater value =
            Maybe.map (\ctx -> updateContextWithValue ctx value)
    in
    List.foldr (\node graph -> Graph.update node.id (graphUpdater node) graph)


{-| The mouse events for drag start, drag at and drag end read the client
position of the cursor, which is relative to the browser viewport. However,
the node positions are relative to the svg viewport. This function adjusts the
coordinates accordingly. It also takes the current zoom level and position
into consideration.
-}



-- View


view : Model -> Svg Msg
view model =
    viewGraph model.graphReady


viewGraph : GraphReady -> Svg Msg
viewGraph graphReady =
    let
        zoomEvents : List (Attribute Msg)
        zoomEvents =
            case graphReady of
                NotYet ->
                    []

                Init _ ->
                    []

                Ready { zoom } ->
                    Zoom.events zoom ZoomMsg

        zoomTransformAttr : Attribute Msg
        zoomTransformAttr =
            case graphReady of
                NotYet ->
                    class []

                Init _ ->
                    class []

                Ready { zoom } ->
                    Zoom.transform zoom
    in
    div
        [ style "width" "80%"
        , style "height" "400px"
        , style "margin" "50px auto"
        , style "border" "2px solid rgba(0, 0, 0, 0.85)"
        ]
        [ svg
            [ id elementId
            , Attrs.width <| Percent 100
            , Attrs.height <| Percent 100
            ]
            [ defs [] [ arrowhead ]
            , -- This transparent rectangle is placed in the background as a
              -- target for the zoom events. Note that the zoom transformation
              -- are not applied to this rectangle, but to group that contains
              -- the actual graph.
              rect
                ([ Attrs.width <| Percent 100
                 , Attrs.height <| Percent 100
                 , fill <| Paint <| Color.rgba 0 0 0 0
                 , cursor CursorMove
                 ]
                    ++ zoomEvents
                )
                []
            , g
                [ zoomTransformAttr ]
                [ renderGraph graphReady ]
            ]
        ]


renderGraph : GraphReady -> Svg Msg
renderGraph graphReady =
    case graphReady of
        NotYet ->
            text ""

        Init _ ->
            text ""

        Ready { graph, showGraph } ->
            if showGraph then
                g
                    []
                    [ Graph.edges graph
                        |> List.map (linkElement graph)
                        |> g [ class [ "links" ] ]
                    , Graph.nodes graph
                        |> List.map nodeElement
                        |> g [ class [ "nodes" ] ]
                    ]

            else
                text ""


{-| Draws a single vertex (node).
-}
nodeElement : Node Entity -> Svg Msg
nodeElement node =
    g [ class [ "node" ] ]
        [ circle
            [ r 20
            , strokeWidth 3
            , fill (Paint Color.yellow)
            , stroke (Paint Color.black)
            , cursor CursorPointer

            -- The coordinates are initialized and updated by `Force.simulation`
            -- and `Force.tick`, respectively.
            , cx node.label.x
            , cy node.label.y

            -- Add event handler for starting a drag on the node.
            , onMouseDown node.id
            ]
            [ title [] [ text node.label.value ] ]
        , text_
            [ -- Align text label at the center of the circle.
              dx <| node.label.x
            , dy <| node.label.y
            , Attrs.alignmentBaseline AlignmentMiddle
            , Attrs.textAnchor AnchorMiddle

            -- styling
            , fontSize <| Px 8
            , fill (Paint Color.black)

            -- Setting pointer events to none allows the user to click on the
            -- element behind the text, so in this case the circle. If you
            -- position the text label outside of the circle, you also should
            -- do this, so that drag and zoom operations are not interrupted
            -- when the cursor is above the text.
            , pointerEvents "none"
            ]
            [ text node.label.value ]
        ]


{-| This function draws the lines between the vertices.
-}
linkElement : Graph Entity () -> Edge () -> Svg msg
linkElement graph edge =
    let
        source =
            Maybe.withDefault (Force.entity 0 "") <|
                Maybe.map (.node >> .label) <|
                    Graph.get edge.from graph

        target =
            Maybe.withDefault (Force.entity 0 "") <|
                Maybe.map (.node >> .label) <|
                    Graph.get edge.to graph
    in
    line
        [ x1 source.x
        , y1 source.y
        , x2 target.x
        , y2 target.y
        , strokeWidth 1
        , stroke edgeColor
        , markerEnd "url(#arrowhead)"
        ]
        []



-- Definitions


{-| This is the definition of the arrow head that is displayed at the end of
the edges.

It is a child of the svg `defs` element and can be referenced by its id with
`url(#arrowhead)`.

-}
arrowhead : Svg msg
arrowhead =
    marker
        [ id "arrowhead"
        , orient "auto"
        , markerWidth <| Px 8.0
        , markerHeight <| Px 6.0
        , refX "29"
        , refY "3"
        ]
        [ polygon
            [ points [ ( 0, 0 ), ( 8, 3 ), ( 0, 6 ) ]
            , fill edgeColor
            ]
            []
        ]



-- Events and tasks


{-| This is the event handler that handles clicks on the vertices (nodes).

The event catches the `clientPos`, which is a tuple with the
`MouseEvent.clientX` and `MouseEvent.clientY` values. These coordinates are
relative to the client area (browser viewport).

If the graph is positioned anywhere else than at the coordinates `(0, 0)`, the
svg element position must be subtracted when setting the node position. This is
handled in the update function by calling the `shiftPosition` function.

-}
onMouseDown : NodeId -> Attribute Msg
onMouseDown index =
    style "background-color" "red"


{-| This function returns a command to retrieve the position of the svg element.
-}
getElementPosition : Cmd Msg
getElementPosition =
    Task.attempt ReceiveElementPosition (Dom.getElement elementId)



-- Main


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- Data


graphData : Graph String ()
graphData =
    Graph.fromNodeLabelsAndEdgePairs
        [ "Fedora Apps"
        , "Upstream"
        , "Infrastructure"
        , "In Development"
        , "Accounts"
        , "Content"
        , "QA"
        , "Coordination"
        , "Packaging"

        --
        , "Easyfix"
        , "DataGrepper"
        , "Status"
        ]
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
