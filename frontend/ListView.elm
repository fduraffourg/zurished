module ListView (Model, initModel, Action(Prev,Next,NoOp), update, view) where

import List
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Debug
import Signal
import Array exposing (Array)

import Struct exposing (Image)

-- MODEL

type alias Model = 
  { content : Array Image
  , current: Image
  , position : Int
  }

initModel : List Image -> Image -> Model
initModel list current =
  { content = Array.fromList list
  , current = current
  , position = getCurrentPosition list current
  }

getCurrentPosition : List Image -> Image -> Int
getCurrentPosition list current =
  let
    isCurrent (index, elm) = if elm == current then Just index else Nothing
    remains = list
      |> List.indexedMap (,)
      |> List.filterMap isCurrent
  in case List.head remains of
    Just index -> index
    Nothing -> 0


-- UPDATE

type Action = Next | Prev | Exit | NoOp

update : Action -> Model -> Model
update action model = case action of
  Next -> let position = model.position + 1
    in case Array.get position model.content of
      Just elm -> { model |
        position = position
        , current = elm
        }
      Nothing -> model
  Prev -> let position = model.position - 1
    in case Array.get position model.content of
      Just elm -> { model |
        position = position
        , current = elm
        }
      Nothing -> model
  _ -> model

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
    [ img [ src model.current.path ] []
    , navButton [("left", "0px")] address Prev
    , navButton [("right", "0px")] address Next
    ]
