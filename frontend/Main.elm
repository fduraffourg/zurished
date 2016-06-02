module Main exposing (..)

import Debug
import Explorer
import Html exposing (..)
import Html.App as App
import Http
import MainMsg exposing (..)
import Struct
import Task
import Viewer


main =
    App.program
        { init = ( initModel, fetchContent )
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { path : String
    , content : Struct.TopContent
    , currentView : View
    , window : ( Int, Int )
    , resizeBoxes : List ( Int, Int )
    }


type View
    = ViewExplorer Explorer.Model
    | ViewViewer Viewer.Model
    | ViewFetchFailed Http.Error


initModel : Model
initModel =
    { path = ""
    , content = Struct.emptyTopContent
    , currentView = ViewExplorer (Explorer.initModel "" [])
    , window = ( 800, 600 )
    , resizeBoxes = []
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        MsgExplorer msg ->
            case model.currentView of
                ViewExplorer modelView ->
                    updateExplorer msg model modelView

                _ ->
                    ( model, Cmd.none )

        MsgViewer msg ->
            case model.currentView of
                ViewViewer modelView ->
                    updateViewer msg model modelView

                _ ->
                    ( model, Cmd.none )

        FetchContentSucceed content ->
            ( { model
                | content = content
                , resizeBoxes = content.sizes
                , currentView =
                    ViewExplorer (Explorer.initModel "" content.images)
              }
            , Cmd.none
            )

        FetchContentFailed error ->
            ( { model | currentView = ViewFetchFailed error }, Cmd.none )

        _ ->
            ( model, Cmd.none )


updateExplorer : Explorer.Msg -> Model -> Explorer.Model -> ( Model, Cmd Msg )
updateExplorer msg model modelView =
    case msg of
        Explorer.ChangePath path ->
            let
                nmv =
                    Explorer.initModel path model.content.images
            in
                ( { model
                    | path = path
                    , currentView = ViewExplorer nmv
                  }
                , Cmd.none
                )

        Explorer.ViewImages list current ->
            ( { model
                | currentView = ViewViewer (Viewer.initModel list current model.resizeBoxes model.window)
              }
            , Cmd.none
            )

        _ ->
            let
                ( newModel, cmd ) =
                    Explorer.update msg modelView
            in
                ( { model | currentView = ViewExplorer newModel }
                , Cmd.map MsgExplorer cmd
                )


updateViewer : Viewer.Msg -> Model -> Viewer.Model -> ( Model, Cmd Msg )
updateViewer msg model modelView =
    case msg of
        Viewer.Exit ->
            ( { model
                | currentView =
                    ViewExplorer
                        (Explorer.initModel model.path
                            model.content.images
                        )
              }
            , Cmd.none
            )

        _ ->
            let
                model =
                    { model
                        | currentView = ViewViewer (Viewer.update msg modelView)
                    }
            in
                ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    case model.currentView of
        ViewExplorer model ->
            App.map MsgExplorer (Explorer.view model)

        ViewViewer model ->
            App.map MsgViewer (Viewer.view model)

        ViewFetchFailed error ->
            div []
                [ text "Failed to fetch image list from server"
                , br [] []
                , text (toString error)
                ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.currentView of
        ViewViewer submodel ->
            Sub.map MsgViewer (Viewer.subscriptions submodel)

        _ ->
            Sub.none



-- Retrieve content from server


fetchContent : Cmd Msg
fetchContent =
    Task.perform FetchContentFailed
        FetchContentSucceed
        (Http.get Struct.topContentDecoder "gallery")
