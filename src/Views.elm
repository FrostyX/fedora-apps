module Views exposing (..)

import Html exposing (Html, button, div, h1, h2, h3, p, text)
import Html.Events exposing (onClick)
import Models exposing (..)


view : Model -> Html Msg
view model =
    div []
        [ case model of
            Apps apps ->
                div [] (apps |> List.map viewAllApps)
        ]


viewAllApps : App -> Html Msg
viewAllApps app =
    div []
        [ h1 [] [ text app.name ]
        , p [] [ text app.data.description ]
        , case app.children of
            Apps apps ->
                div [] (apps |> List.map viewAppGroup)
        ]


viewAppGroup : App -> Html Msg
viewAppGroup app =
    div []
        [ h2 [] [ text app.name ]
        , p [] [ text app.data.description ]
        , case app.children of
            Apps apps ->
                div [] (apps |> List.map viewApp)
        ]


viewApp : App -> Html Msg
viewApp app =
    div []
        [ h3 [] [ text app.name ]
        , p [] [ text app.data.description ]
        ]
