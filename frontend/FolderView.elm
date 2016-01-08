module FolderView (Model, initModel, view, Action(ChangePath, NoOp)) where

import Struct
import String
import List
import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (style)
import Signal

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


type Action = ChangePath String | NoOp

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
    pathList = ul [ style cssPathList ]
      (List.intersperse (li [ style cssPathItem ] [ text "/" ]) pathElmts)

    -- CONTENT
    folderItems = List.map (folderToItem address) model.folders
    imageItems = List.map (imageToItem address) model.content
    contentList = ul [ style cssContentList ]
      (folderItems ++ imageItems)
  in
    div []
      [ h1 [ style cssTitle ] [ text title ]
      , pathList
      , contentList
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
    li [ style cssImageItem ] [ text path ]

pathToItem : Signal.Address Action -> (String, String) -> Html
pathToItem address (path,name) =
  li
    [ onClick address (ChangePath path)
    , style cssPathItem ]
    -- [ text (name ++ " - " ++ path) ]
    [ text name ]

folderToItem : Signal.Address Action -> Struct.Folder -> Html
folderToItem address {path, name} =
  li
    [ onClick address (ChangePath path), style cssFolderItem ]
    -- [ text (name ++ " - " ++ path) ]
    [ text name ]


-- CSS

-- color1 = "#e5f4e3"
-- color2 = "#5da9e9"
-- color3 = "#003f91"
-- color4 = "#ffffff"
-- color5 = "#6d326d"
color1 = "#086788"
color2 = "#06aed5"
color3 = "#f0c808"
color4 = "#fff1d0"
color5 = "#dd1c1a"

cssClickable = [("cursor", "pointer")]

cssTitle = [("margin", "0px"), ("background-color", color1), ("color", "white")
  , ("padding", "20px"), ("text-align", "center")]

cssPathList = [("padding", "5px"), ("background-color", color2), ("margin", "0px")
  , ("padding", "14px"), ("color", "white"), ("font-weight", "bold")]
cssPathItem = cssClickable ++ [("display", "inline-block"), ("padding", "0px 5px")]

cssVerticalList = [("list-style-type", "none"), ("padding", "5px")]
cssVerticalItem = [("margin", "2px"), ("padding", "8px"), ("background-color", color4)]

cssContentList = cssVerticalList
cssFolderItem = cssClickable ++ cssVerticalItem ++
  [ ("background-color", color3), ("color", "white") ]
cssImageItem = cssVerticalItem
