module Widgets exposing (mainError)

import Html exposing (Html, div, br, text)
import Html.Attributes exposing (class)


mainError : String -> String -> Html a
mainError message error =
    div [ class "mainError" ]
        [ div [ class "message" ] [ text message ]
        , div [ class "error" ] [ text error ]
        ]
