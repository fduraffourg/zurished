module FolderView (Model, initModel, view, Action(Goto, NoOp)) where

import Struct
import String
import List
import Html exposing (..)
import Html.Events exposing (onClick)
import Signal

-- MODEL

type alias Model =
  { path : String
  , images : List Struct.Image
  }

initModel : String -> List Struct.Image -> Model
initModel path images =
  let
    path = if String.endsWith "/" path then String.slice 0 -1 path else path
  in
    { path = path
    , images = List.filter (Struct.imageInPath path) images
    }


type Action = Goto String | NoOp

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  let
    imageList = ul [] (List.map (imageToItem address) model.images)
    folderList = ul []
      (String.split "/" model.path
        |> List.foldl foldPath [("", "[root]")]
        |> List.reverse
        |> List.map (folderToItem address)
      )
  in
    div []
      [ h1 [] [ text model.path ]
      , folderList
      , imageList
      ]


foldPath : String -> List (String, String) -> List (String, String)
foldPath part prev =
  let
    (prevPath, _) = Maybe.withDefault ("", "") (List.head prev)
    newItem = (prevPath ++ "/" ++ part, part)
  in
    newItem :: prev

imageToItem : Signal.Address Action -> Struct.Image -> Html
imageToItem address image =
  let
    path = image.path
    name = path
      |> String.split "/"
      |> List.foldl (\a b -> a) ""
  in
    li [] [ text name ]

folderToItem : Signal.Address Action -> (String, String) -> Html
folderToItem address (path,name) = li [ onClick address (Goto path) ] [ text name ]
