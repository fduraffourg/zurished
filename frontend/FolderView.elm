module FolderView (Model, initModel, view, Action(ChangePath, NoOp)) where

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
  , folders : List Struct.Folder
  , content : List Struct.Image
  }

initModel : String -> List Struct.Image -> Model
initModel path images =
  let
    path = Struct.normPath path
    -- content = Struct
  in
    { path = path
    , images = List.filter (Struct.imageInSubDirs path) images
    , folders = Struct.listFolders path images
    , content = List.filter (Struct.imageInDir path) images
    }


type Action = ChangePath String | NoOp

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  let
    imageList = ul [] (List.map (imageToItem address) model.content)
    pathList = ul []
      (String.split "/" model.path
        |> List.foldl foldPath [("", "[root]")]
        |> List.reverse
        |> List.map (pathToItem address)
      )
    folderList = ul []
      (List.map (folderToItem address) model.folders)
    title = if model.path == "" then "[root]" else model.path
  in
    div []
      [ h1 [] [ text title ]
      , h2 [] [ text "Path" ]
      , pathList
      , h2 [] [ text "Sub Folders" ]
      , folderList
      , h2 [] [ text "Images" ]
      , imageList
      ]


foldPath : String -> List (String, String) -> List (String, String)
foldPath part prev =
  let
    (prevPath, _) = Maybe.withDefault ("", "") (List.head prev)
    newItem = (Struct.pathMerge prevPath part, part)
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
    li [] [ text path ]

pathToItem : Signal.Address Action -> (String, String) -> Html
pathToItem address (path,name) =
  li
    [ onClick address (ChangePath path) ]
    -- [ text (name ++ " - " ++ path) ]
    [ text name ]

folderToItem : Signal.Address Action -> Struct.Folder -> Html
folderToItem address {path, name} =
  li
    [ onClick address (ChangePath path) ]
    -- [ text (name ++ " - " ++ path) ]
    [ text name ]

