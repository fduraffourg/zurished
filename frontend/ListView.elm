module ListView (Model, initModel, Action(Prev,Next,Exit,ChangeWindowSize,NoOp), update, view) where

import List
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Debug
import Signal
import Array exposing (Array)
import Basics exposing (round, toFloat, min)

import Struct exposing (Image)

-- MODEL

type alias Model = 
  { content : Array Image
  , current: Image
  , position : Int
  , window : (Int, Int)
  , resizeBoxes : List (Int, Int)
  , resizeBox : (Int, Int)
  }

initModel : List Image -> Image -> List (Int, Int) -> (Int, Int) -> Model
initModel list current resizeBoxes window =
  { content = Array.fromList list
  , current = current
  , position = getCurrentPosition list current
  , window = window
  , resizeBoxes = resizeBoxes
  , resizeBox = chooseResizeBox resizeBoxes window
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

type Action = Next | Prev | Exit | ChangeWindowSize (Int, Int) | NoOp

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
  ChangeWindowSize window ->
      { model | window = window
                , resizeBox = chooseResizeBox model.resizeBoxes window}
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

exitButton : Signal.Address Action -> Html
exitButton address =
  div [ style
        [ ("position", "absolute")
        , ("width", "80px")
        , ("height", "80px")
        , ("top", "0px")
        , ("right", "0px")
        , ("background-color", "gray")
        ]
      , onClick address Exit]
      []


view: Signal.Address Action -> Model -> Html
view address model =
  let
    (boxw, boxh) = model.resizeBox
    path = "/medias/resized/" ++ (toString boxw) ++ "x" ++ (toString boxh) ++ "/" ++ model.current.path
    (imgw, imgh) = getImageSize model.current model.window
    (winw, _) = model.window
    left = round (toFloat (winw - imgw) / 2)
  in div []
    [ img [ src path
          , width imgw
          , height imgh
          , style [("margin-left", (toString left) ++ "px")]] []
    , navButton [("left", "0px")] address Prev
    , navButton [("right", "0px")] address Next
    , exitButton address
    ]


-- UTILS

getImageSize : Image -> (Int, Int) -> (Int, Int)
getImageSize image (winw, winh) =
  let
    natural = (toFloat image.width, toFloat image.height)
    wcons = (toFloat winw, (toFloat winw) * (toFloat image.height) / (toFloat image.width))
    hcons = ((toFloat winh) * (toFloat image.width) / (toFloat image.height), toFloat winh)
    (fwidth, fheight) = Basics.min natural (Basics.min wcons hcons)
  in
    (round fwidth, round fheight)

chooseResizeBox : List (Int, Int) -> (Int, Int) -> (Int, Int)
chooseResizeBox sizes (winw, winh) =
  let
    keepSmaller (w, h) = if w > winw && h > winh then False else True
    smallers = List.filter keepSmaller sizes
  in case List.maximum smallers of
    Just size -> size
    Nothing -> case List.head sizes of
        Just size -> size
        Nothing -> Debug.log "Scress is to small" (0, 0)
