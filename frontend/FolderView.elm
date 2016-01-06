module FolderView (Model, initModel, view) where

import Struct
import String
import List
import Html exposing (..)

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


-- VIEW

view : Model -> Html
view model =
  let
    imageList = ul [] (List.map imageToItem model.images)
    folderList = ul []
      (String.split "/" model.path
        |> List.map folderToItem)
  in
    div []
      [ h1 [] [ text model.path ]
      , folderList
      , imageList
      ]

imageToItem : Struct.Image -> Html
imageToItem image = li [] [ text image.path ]

folderToItem : String -> Html
folderToItem name = li [] [ text name ]
