module ImageView (Model, init, Action, update, view) where

import Html exposing (..)
import Html.Attributes exposing (src)

-- MODEL

type alias Model = String

init : String -> Model
init url = url


-- UPDATE

type Action = Modify String

update : Action -> Model -> Model
update action model =
    case action of
        Modify url -> url


-- VIEW

view : Model -> Html
view model =
  div []
    [ img [ src model ] [] ]
