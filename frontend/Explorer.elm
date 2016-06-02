module Explorer exposing (Model, initModel, view, Msg(ChangePath, ViewImages, NoOp))

import Struct
import String
import List
import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (src, width, height, id, class, classList)
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
        path =
            Struct.normPath path

        -- content = Struct
    in
        { path = path
        , folders = Struct.listFolders path images
        , content = List.filter (Struct.imageInDir path) images
        }



-- UPDATE


type Msg
    = ChangePath String
    | NoOp
    | ViewImages (List Struct.Image) Struct.Image


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- VIEW


rootName =
    "Top"


view : Model -> Html Msg
view model =
    let
        title =
            if model.path == "" then
                rootName
            else
                model.path

        -- PATH
        path =
            if model.path == "" then
                [ ( "", rootName ) ]
            else
                String.split "/" model.path
                    |> List.foldl foldPath [ ( "", rootName ) ]
                    |> List.reverse

        pathElmts =
            List.map (pathToItem) path

        pathList =
            ul [ id "fv-path" ]
                (List.intersperse (li [] [ text "/" ]) pathElmts)
    in
        div []
            [ h1 [] [ text title ]
            , pathList
            , iconView model
            ]


foldPath : String -> List ( String, String ) -> List ( String, String )
foldPath part prev =
    let
        ( prevPath, _ ) =
            Maybe.withDefault ( "", "" ) (List.head prev)

        newItem =
            ( Struct.pathMerge prevPath part, part )
    in
        newItem :: prev


pathToItem : ( String, String ) -> Html Msg
pathToItem ( path, name ) =
    li [ onClick (ChangePath path) ]
        -- [ text (name ++ " - " ++ path) ]
        [ text name ]



-----------
-- ICONVIEW
-----------


iconView : Model -> Html Msg
iconView model =
    let
        folderItems =
            List.map iconViewFolderToItem model.folders

        imageItems =
            List.map (iconViewImageToItem model.content)
                model.content

        folderList =
            ul [ classList [ ( "fv-list", True ), ( "fv-folder-list", True ) ] ] folderItems

        imageList =
            ul [ classList [ ( "fv-list", True ), ( "fv-image-list", True ) ] ] imageItems
    in
        div []
            [ folderList
            , imageList
            ]


iconViewImageToItem : List Struct.Image -> Struct.Image -> Html Msg
iconViewImageToItem allImages image =
    let
        path =
            "/medias/thumbnail/" ++ image.path
    in
        li [ onClick (ViewImages allImages image) ]
            [ img [ src path, width 150, height 150 ] [] ]


iconViewFolderToItem : Struct.Folder -> Html Msg
iconViewFolderToItem { path, name } =
    li [ onClick (ChangePath path) ]
        -- [ text (name ++ " - " ++ path) ]
        [ FontAwesome.folder (Color.greyscale 0) 70
        , br [] []
        , text name
        ]
