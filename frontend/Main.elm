import Signal
import Html exposing (..)
import Task
import Http
import Struct
import Debug
import FolderView
import ListView

main : Signal Html
main = Signal.map view
  (Signal.foldp update initModel mb.signal)



-- MODEL

type alias Model =
  { path : String
  , content : Struct.TopContent
  , currentView : View
  }

type View = ExplorerView | ImageView ListView.Model

initModel : Model
initModel = { path = "", content = Struct.emptyTopContent, currentView = ExplorerView }



-- UPDATE

mb = Signal.mailbox NoOp

type Action = UpdateContent Struct.TopContent | ChangePath String | ViewImages (List Struct.Image) Struct.Image | ForwardViewer ListView.Action | NoOp

update : Action -> Model -> Model
update action model  =
  case action of
    UpdateContent content -> { model | content = content }
    ChangePath path -> { model | path = path }
    ViewImages list current ->
      { model |
        currentView = ImageView (ListView.initModel list current) }
    ForwardViewer lvaction ->
      case model.currentView of
        ImageView lvmodel -> { model |
          currentView = ImageView (ListView.update lvaction lvmodel) }
        _ -> model
    NoOp -> model



-- VIEW

view : Model -> Html
view model =
  case model.currentView of
    ExplorerView -> FolderView.view
      explorerAddress
      (FolderView.initModel model.path model.content.images)
    ImageView model -> ListView.view viewerAddress model


listStringToHtml string = li [] [ text string ]



-- Explorer connectors

explorerAddress = Signal.forwardTo mb.address signalExplorerToMain

signalExplorerToMain : FolderView.Action -> Action
signalExplorerToMain action = case action of
  FolderView.ChangePath path -> ChangePath path
  FolderView.NoOp -> NoOp
  FolderView.ViewImages list current -> ViewImages list current


-- Viewer connectors

viewerAddress = Signal.forwardTo mb.address signalViewerToMain

signalViewerToMain : ListView.Action -> Action
signalViewerToMain action = ForwardViewer action


-- Retrieve content from server

httpAddress = Signal.forwardTo mb.address signalHttpToMain

signalHttpToMain : Struct.TopContent -> Action
signalHttpToMain content = UpdateContent content


port fetchString : Task.Task Http.Error ()
port fetchString = Task.andThen
  (Task.onError
    (Http.get Struct.topContentDecoder "albums.json")
    (\msg -> Task.fail (Debug.log "Http.get error:" msg)))
  (Signal.send httpAddress)

