module Struct (TopContent, emptyTopContent, Image, topContentDecoder, topFolders) where

import Json.Decode as Json exposing ((:=), Decoder, string, list)
import String
import List

type alias TopContent =
  { sizes : List String
  , images : List Image
  }

type alias Image =
  { path : String
  }

emptyTopContent =
  { sizes = []
  , images = []
  }

-- JSON Decoder

topContentDecoder : Decoder TopContent
topContentDecoder = Json.object2 TopContent
  ("sizes" := list string)
  ("images" := list imageDecoder)

imageDecoder : Decoder Image
imageDecoder = Json.object1 Image
  ("name" :=  string)


-- Usefull functions on image list

isJust elmt = case elmt of
  Just _ -> True
  Nothing -> False


listUnique : List String -> List String
listUnique list =
  let
    add new cur = case List.head(cur) of
      Just elmt -> if elmt == new then cur else new :: cur
      Nothing -> [ new ]
  in
    list
      |> List.sort
      |> List.foldr add []


topFolders : List Image -> List String
topFolders list =
  list
  |> List.map .path
  |> (List.map (String.split "/"))
  |> (List.map List.head)
  |> List.filter isJust
  |> List.map (Maybe.withDefault "")
  |> listUnique
