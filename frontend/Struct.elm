module Struct exposing (TopContent, emptyTopContent, Image, Folder, topContentDecoder, topFolders, imageInSubDirs, imageInDir, listFolders, pathMerge, normPath)

import Json.Decode as Json exposing ((:=), Decoder, tuple2, int, string, list)
import String
import List


type alias TopContent =
    { sizes : List ( Int, Int )
    , images : List Image
    }


type alias Image =
    { path : String
    , width : Int
    , height : Int
    }


type alias Folder =
    { path : String
    , name : String
    }


emptyTopContent =
    { sizes = []
    , images = []
    }



-- JSON Decoder


topContentDecoder : Decoder TopContent
topContentDecoder =
    Json.object2 TopContent
        ("sizes" := list (tuple2 (,) int int))
        ("images" := list imageDecoder)


imageDecoder : Decoder Image
imageDecoder =
    Json.object3 Image
        ("path" := string)
        ("width" := int)
        ("height" := int)



-- Usefull functions on image list


isJust elmt =
    case elmt of
        Just _ ->
            True

        Nothing ->
            False


listUnique : List String -> List String
listUnique list =
    let
        add new cur =
            case List.head (cur) of
                Just elmt ->
                    if elmt == new then
                        cur
                    else
                        new :: cur

                Nothing ->
                    [ new ]
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


listFolders : String -> List Image -> List Folder
listFolders path list =
    let
        isGT2 list =
            if (List.length list) > 1 then
                True
            else
                False

        listFolders =
            list
                |> List.map .path
                |> List.filterMap (relativePath path)
                |> List.map (String.split "/")
                |> List.filter isGT2
                |> List.filterMap List.head
                |> listUnique

        listPaths =
            listFolders
                |> List.map (pathMerge path)

        tupleToFolder path name =
            { path = path, name = name }
    in
        List.map2 tupleToFolder listPaths listFolders



-- True if image belongs to the given path or to any sub-folder of the given
-- path


imageInSubDirs : String -> Image -> Bool
imageInSubDirs path image =
    if String.startsWith path image.path then
        True
    else
        False



-- True if image is in the given path


imageInDir : String -> Image -> Bool
imageInDir path image =
    case relativePath path image.path of
        Nothing ->
            False

        Just relpath ->
            if String.contains "/" relpath then
                False
            else
                True


pathMerge : String -> String -> String
pathMerge start end =
    case ( start, end ) of
        ( "", "" ) ->
            ""

        ( "", end ) ->
            end

        ( start, "" ) ->
            start

        ( start, end ) ->
            start ++ "/" ++ end


relativePath : String -> String -> Maybe String
relativePath start full =
    if start == "" then
        Just full
    else
        let
            slashedStart =
                if String.endsWith "/" start then
                    start
                else
                    start ++ "/"
        in
            if String.startsWith slashedStart full then
                Just (String.dropLeft (String.length slashedStart) full)
            else
                Nothing


normPath : String -> String
normPath path =
    if String.endsWith "/" path then
        String.slice 0 -1 path
    else
        path
