module Views exposing (..)

import AppGraph
import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Popover as Popover
import Browser.Dom
import Color
import Dict exposing (Dict)
import Hovercard exposing (hovercard)
import Html
    exposing
        ( Html
        , a
        , button
        , div
        , form
        , h1
        , h2
        , h3
        , hr
        , img
        , input
        , node
        , p
        , span
        , text
        )
import Html.Attributes
    exposing
        ( attribute
        , class
        , href
        , id
        , name
        , placeholder
        , rel
        , src
        , style
        , value
        , width
        )
import Html.Events exposing (onClick, onInput)
import Html.Parser
import Html.Parser.Util
import List.Split
import Logic exposing (..)
import Models exposing (..)
import Set exposing (Set)


view : Model -> Html Msg
view model =
    div []
        [ CDN.stylesheet -- creates an inline style node with the Bootstrap CSS
        , node "link" [ rel "stylesheet", href "/css/style.css" ] []
        , viewMenu
        , div [ class "container content" ]
            [ case model.apps of
                Apps apps ->
                    div [] (apps |> List.map (viewAllApps model))
            ]
        ]


viewMenu : Html Msg
viewMenu =
    div [ id "menu", class "container-fluid" ]
        [ div [ class "container" ]
            [ Html.nav
                [ class "navbar"
                , class "navbar-expand-lg"
                ]
                [ viewLogo
                , div
                    [ class "navbar-nav"
                    , class "ml-auto"
                    ]
                    [ form [ class "form-inline" ]
                        [ input
                            [ class "form-control form-control-sm"
                            , placeholder "Search"
                            , onInput Search
                            ]
                            []
                        ]
                    , viewMenuItem "New App"
                        "#"
                    , viewMenuItem "Source code"
                        "https://github.com/frostyx/fedora-apps/"
                    ]
                ]
            ]
        ]


viewMenuItem : String -> String -> Html Msg
viewMenuItem title url =
    a [ class "nav-link", class "nav-item", href url ]
        [ text title ]


viewLogo : Html Msg
viewLogo =
    a [ id "logo", class "navbar-brand", href "/" ]
        [ img [ src "/img/apps-logo.svg" ] [] ]


viewGraph : GraphReady -> Html Msg
viewGraph graphReady =
    div [] [ AppGraph.viewGraph graphReady [ id "graph" ] ]


viewAllApps : Model -> App -> Html Msg
viewAllApps model app =
    div []
        [ div [ class "row justify-content-md-center", id "header" ]
            [ div [ class "col-8" ]
                [ h1 [] [ text app.name ]
                , p [] (viewAppDescription app)
                ]
            ]
        , viewGraph model.graphReady
        , case app.children of
            Apps apps ->
                div [] (apps |> List.map (viewAppGroup model))
        ]


viewAppGroup : Model -> App -> Html Msg
viewAppGroup model app =
    let
        visibleChildren =
            case app.children of
                Apps apps ->
                    apps
                        |> List.filter
                            (\a ->
                                not <| Set.member a.name model.hiddenApps
                            )
    in
    if List.isEmpty visibleChildren then
        div [] []

    else
        div [ class "app-group" ]
            [ div [ class "app-group-header row justify-content-md-center" ]
                [ div [ class "col col-lg-10" ]
                    [ h2 [] [ text app.name ]
                    , p [] (viewAppDescription app)
                    ]
                ]
            , div [ class "app-rows" ]
                (visibleChildren
                    |> List.Split.chunksOfLeft 5
                    |> List.map (viewAppRow model)
                )
            ]


viewAppRow : Model -> List App -> Html Msg
viewAppRow model apps =
    div [ class "row" ]
        [ div [ class "col-12" ]
            [ div [ class "card-deck" ]
                (apps |> List.map (viewApp model))
            ]
        ]


viewApp : Model -> App -> Html Msg
viewApp model app =
    let
        popoverState =
            Dict.get app.name model.popoverState
                |> Maybe.withDefault
                    Popover.initialState

        hidden =
            Set.member app.name model.hiddenApps
    in
    if hidden then
        div [] []

    else
        Popover.config
            (div [ class "mb-4" ]
                [ Card.config
                    [ Card.attrs <| Popover.onHover popoverState (PopoverMsg app)
                    ]
                    |> Card.imgTop [ src (appIcon app) ] []
                    |> Card.block []
                        [ Block.titleH3 [] [ text app.name ]
                        ]
                    |> Card.view
                ]
            )
            |> Popover.top
            |> Popover.titleH4 []
                [ div []
                    [ viewAppIcon app
                    , text app.name
                    ]
                ]
            |> Popover.content []
                (viewAppDescription app)
            |> Popover.view popoverState


viewAppDetail : App -> Html Msg
viewAppDetail app =
    div []
        [ h3 [] [ text app.name ]
        , p [] (viewAppDescription app)
        , p [] [ a [ href app.data.url ] [ text app.data.url ] ]
        , p [] [ a [ href app.data.bugs_url ] [ text app.data.bugs_url ] ]
        , p [] [ a [ href app.data.docs_url ] [ text app.data.docs_url ] ]
        , viewAppIcon app
        , hr [] []
        ]


viewAppIcon : App -> Html Msg
viewAppIcon app =
    img [ src (appIcon app) ] []


viewAppDescription : App -> List (Html Msg)
viewAppDescription app =
    case Html.Parser.run app.data.description of
        Ok html ->
            Html.Parser.Util.toVirtualDom html

        Err err ->
            [ text (Debug.toString err) ]
