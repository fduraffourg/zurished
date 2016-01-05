module ImageView (Model, init, Action, update, view) where

import Html exposing (..)
import Html.Attributes exposing (src, style)
import Window

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

view : (Int, Int) -> Model -> Html
view (w,h) model =
  let
    width = (toString (w-5)) ++ "px"
    height = (toString (h-5)) ++ "px"
  in
    div [ style [ ("width", width), ("height", height)]]
    [ img
      [ src model
      , style [ ("max-width", width), ("max-height", height), ("margin", "auto") ]
      ]
      [] ]
