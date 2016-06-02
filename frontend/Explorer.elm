module Explorer exposing (Model, initModel, update, view, Msg(..))

import Struct
import String
import List
import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (src, width, height, id, class, classList, placeholder, type', value)
import FontAwesome
import Color
import Debug


-- MODEL


type alias Model =
    { path : String
    , folders : List Struct.Folder
    , showFolders : List Struct.Folder
    , content : List Struct.Image
    , search : String
    }


initModel : String -> List Struct.Image -> Model
initModel path images =
    let
        path =
            Struct.normPath path

        folders =
            Struct.listFolders path images

        -- content = Struct
    in
        { path = path
        , folders = folders
        , showFolders = folders
        , content = List.filter (Struct.imageInDir path) images
        , search = ""
        }



-- UPDATE


type Msg
    = ChangePath String
    | NoOp
    | ViewImages (List Struct.Image) Struct.Image
    | Search String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Search pattern ->
            if String.isEmpty pattern then
                ( { model | search = "", showFolders = model.folders }, Cmd.none )
            else
                ( { model
                    | search = pattern
                    , showFolders = filterFolders model.folders pattern
                  }
                , Cmd.none
                )

        _ ->
            ( model, Cmd.none )


filterFolders : List Struct.Folder -> String -> List Struct.Folder
filterFolders folders pattern =
    let
        pattern =
            String.toLower pattern
    in
        List.filter (\f -> String.contains pattern (String.toLower f.name)) folders



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

        -- SEARCH
        searchInput =
            input
                [ placeholder "Search folders"
                , type' "text"
                , onInput Search
                , value model.search
                ]
                []

        searchBar =
            div [ id "fv-searchbar" ] [ searchInput ]
    in
        div []
            [ h1 [] [ text title ]
            , pathList
            , searchBar
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
            List.map iconViewFolderToItem model.showFolders

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
