module ListView (Model, initModel, Action(Prev,Next,Exit,ChangeWindowSize,NoOp), update, view) where

import List
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (width, height, classList, style, src, id, class)
import Debug
import Signal
import Array exposing (Array)
import Basics exposing (round, toFloat, min)
import Maybe
import FontAwesome
import Color

import Struct exposing (Image)

-- MODEL

type alias Model = 
  { content : Array Image
  , current: Image
  , position : Int
  , window : (Int, Int)
  , resizeBoxes : List (Int, Int)
  , resizeBox : (Int, Int)
  , currentUrl : String
  , preloadUrl : Maybe String
  }

initModel : List Image -> Image -> List (Int, Int) -> (Int, Int) -> Model
initModel list current resizeBoxes window =
  let
      resizeBox = chooseResizeBox resizeBoxes window
  in
  { content = Array.fromList list
  , current = current
  , position = getCurrentPosition list current
  , window = window
  , resizeBoxes = resizeBoxes
  , resizeBox = resizeBox
  , currentUrl = getUrl resizeBox current
  , preloadUrl = Nothing
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
        , currentUrl = getUrl model.resizeBox elm
        , preloadUrl = Array.get (position+1) model.content
            |> Maybe.map (getUrl model.resizeBox)
        }
      Nothing -> model
  Prev -> let position = model.position - 1
    in case Array.get position model.content of
      Just elm -> { model |
        position = position
        , current = elm
        , currentUrl = getUrl model.resizeBox elm
        , preloadUrl = Nothing
        }
      Nothing -> model
  ChangeWindowSize window ->
      { model | window = window
                , resizeBox = chooseResizeBox model.resizeBoxes window}
  _ -> model

-- VIEW

navButton : List (String, String) -> Signal.Address Action -> Action -> Html
navButton cstyle address action =
  let
    (content, cssid) = case action of
        Prev -> (FontAwesome.chevron_left, "iv-button-prev")
        Next -> (FontAwesome.chevron_right, "iv-button-next")
        Exit -> (FontAwesome.times, "iv-button-exit")
        _ -> (FontAwesome.chain_broken, "")

    icolor = Color.greyscale 0.5
    isize = 70
  in div
    [ onClick address action
    , id cssid
    , class "iv-button"
    ]
    [div [] [content icolor isize]]

view: Signal.Address Action -> Model -> Html
view address model =
  let
    (boxw, boxh) = model.resizeBox
    sizeClass = if imageConstraintByHeight model.current model.window
                   then "img-fullheight"
                   else "img-fullwidth"
    preload = Maybe.withDefault "" model.preloadUrl
  in div []
    [ img [ src preload, width 0, height 0, style [("display", "none")] ][]
    , div [ id "iv-img-container" ]
          [ img [ src model.currentUrl
                , class sizeClass
                ] []
          ]
    , if model.position /= 0 then navButton [] address Prev else div [][]
    , if model.position /= ((Array.length model.content) - 1) then navButton [] address Next else div [][]
    , div [ id "iv-toolbar" ]
        [ navButton [] address Exit
        ]
    ]


-- UTILS

imageConstraintByHeight : Image -> (Int, Int) -> Bool
imageConstraintByHeight image (winw, winh) =
  let
    height = round (toFloat (winw * image.height) / (toFloat image.width))
  in height >= winh

chooseResizeBox : List (Int, Int) -> (Int, Int) -> (Int, Int)
chooseResizeBox sizes (winw, winh) =
  let
    keepSmaller (w, h) = if w > winw || h > winh then False else True
    smallers = List.filter keepSmaller sizes
  in case List.maximum smallers of
    Just size -> size
    Nothing -> case List.head sizes of
        Just size -> size
        Nothing -> Debug.log "Scress is to small" (0, 0)

getUrl : (Int, Int) -> Image -> String
getUrl (boxw, boxh) image =
    "/medias/resized/" ++ (toString boxw) ++ "x" ++ (toString boxh) ++ "/" ++ image.path
