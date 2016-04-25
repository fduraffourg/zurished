module FolderView (Model, initModel, view, Action(ChangePath, ViewImages, NoOp)) where

import Struct
import String
import List
import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (src, width, height, id, class, classList)
import Signal
import FontAwesome
import Color

-- MODEL

type alias Model =
  { path : String
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
    , folders = Struct.listFolders path images
    , content = List.filter (Struct.imageInDir path) images
    }


type Action = ChangePath String | NoOp | ViewImages (List Struct.Image) Struct.Image

-- VIEW

rootName = "Top"

view : Signal.Address Action -> Model -> Html
view address model =
  let
    title = if model.path == "" then rootName else model.path

    -- PATH
    path = if model.path == "" then [("", rootName)] else
      String.split "/" model.path
        |> List.foldl foldPath [("", rootName)]
        |> List.reverse
    pathElmts = List.map (pathToItem address) path
    pathList = ul [ id "fv-path" ]
      (List.intersperse (li [] [ text "/" ]) pathElmts)

    -- CONTENT
    folderItems = List.map (folderToItem address) model.folders
    imageItems = List.map
      (imageToItem address model.content)
      model.content
    folderList = ul [classList [("fv-list", True), ("fv-folder-list", True)]] folderItems
    imageList = ul [classList [("fv-list", True), ("fv-image-list", True)]] imageItems

  in
    div []
      [ h1 [] [ text title ]
      , pathList
      , folderList
      , imageList
      ]


foldPath : String -> List (String, String) -> List (String, String)
foldPath part prev =
  let
    (prevPath, _) = Maybe.withDefault ("", "") (List.head prev)
    newItem = (Struct.pathMerge prevPath part, part)
  in
    newItem :: prev

imageToItem : Signal.Address Action -> List Struct.Image -> Struct.Image -> Html
imageToItem address allImages image =
  let
    path = "/medias/thumbnail/" ++ image.path
  in
    li
      [ onClick address (ViewImages allImages image) ]
      [ img [ src path, width 150, height 150] [] ]

pathToItem : Signal.Address Action -> (String, String) -> Html
pathToItem address (path,name) =
  li
    [ onClick address (ChangePath path) ]
    -- [ text (name ++ " - " ++ path) ]
    [ text name ]

folderToItem : Signal.Address Action -> Struct.Folder -> Html
folderToItem address {path, name} =
  li
    [ onClick address (ChangePath path)]
    -- [ text (name ++ " - " ++ path) ]
    [ FontAwesome.folder (Color.greyscale 0) 70
    , br [] []
    , text name ]
