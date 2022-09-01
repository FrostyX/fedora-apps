module Views exposing (..)

import Bootstrap.CDN as CDN
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Html
    exposing
        ( Html
        , a
        , button
        , div
        , h1
        , h2
        , h3
        , hr
        , img
        , p
        , text
        )
import Html.Attributes
    exposing
        ( attribute
        , class
        , href
        , id
        , name
        , rel
        , src
        , style
        , value
        , width
        )
import Html.Events exposing (onClick)
import Html.Parser
import Html.Parser.Util
import Models exposing (..)


view : Model -> Html Msg
view model =
    Grid.container []
        [ CDN.stylesheet -- creates an inline style node with the Bootstrap CSS
        , Grid.row []
            [ Grid.col []
                [ case model of
                    Apps apps ->
                        div [] (apps |> List.map viewAllApps)
                ]
            ]
        ]


viewAllApps : App -> Html Msg
viewAllApps app =
    div []
        [ h1 [] [ text app.name ]
        , p [] (viewAppDescription app)
        , case app.children of
            Apps apps ->
                div [] (apps |> List.map viewAppGroup)
        ]


viewAppGroup : App -> Html Msg
viewAppGroup app =
    div []
        [ h2 [] [ text app.name ]
        , p [] (viewAppDescription app)
        , div [ class "card-deck" ]
            (case app.children of
                Apps apps ->
                    apps |> List.map viewApp
            )
        ]


viewApp : App -> Html Msg
viewApp app =
    Card.config [ Card.outlineInfo ]
        |> Card.imgTop [ src (appIcon app) ] []
        |> Card.block []
            [ Block.titleH3 [] [ text app.name ]
            ]
        |> Card.view


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


appIcon : App -> String
appIcon app =
    "/img/icons/" ++ app.data.icon


viewAppDescription : App -> List (Html Msg)
viewAppDescription app =
    case Html.Parser.run app.data.description of
        Ok html ->
            Html.Parser.Util.toVirtualDom html

        Err err ->
            [ text (Debug.toString err) ]
