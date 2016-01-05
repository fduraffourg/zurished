module ListView (Model, init, Action(Prev,Next,NoOp), update, view) where

import List
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Debug
import Signal

import ImageView

-- MODEL

type alias Model = 
  { previous: List String
  , current: String
  , next: List String
  }

init : List String -> Model
init images =
  { previous = []
  , current = Maybe.withDefault "" (List.head images)
  , next = Maybe.withDefault [] (List.tail images)
  }


-- UPDATE

type Position = Start | Inside | End

position : Model -> Position
position model =
  if List.isEmpty model.previous then Start else
  if List.isEmpty model.next then End else
  Inside


type Action = Next | Prev | NoOp

update : Action -> Model -> Model
update action model =
    case (position model, action) of
        (Start, Prev) -> model
        (End, Next) -> model
        (_, Next) ->
          { previous = List.append model.previous [model.current]
          , current = Maybe.withDefault "" (List.head model.next)
          , next = Maybe.withDefault [] (List.tail model.next)
          }
        (_, Prev) ->
          let start = (List.length model.previous) - 1
          in
          { previous = List.take start model.previous
          , current = Maybe.withDefault "" (List.head (List.drop start model.previous))
          , next = model.current :: model.next
          }
        (_, _) -> model

-- VIEW

navButton : List (String, String) -> Signal.Address Action -> Action -> Html
navButton cstyle address action =
  let navStyle =
    [ ("position", "absolute")
    , ("width", "50%")
    , ("height", "100%")
    , ("top", "0px")
    ]
  in div
    [ onClick address action
    , style (List.append navStyle cstyle)
    ]
    []

view: Signal.Address Action -> Model -> Html
view address model =
  div []
    [ ImageView.view  model.current
    , navButton [("left", "0px")] address Prev
    , navButton [("right", "0px")] address Next
    ]
