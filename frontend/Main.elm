import Signal
import Html exposing (..)
import Task
import Http
import Struct
import Debug
import FolderView
import ListView
import Window
import Keyboard

main : Signal Html
main = Signal.map view
  (Signal.foldp update initModel
    (Signal.mergeMany
        [ mb.signal
        , windowSignal
        , keyboardSignal
        ])
  )



-- MODEL

type alias Model =
  { path : String
  , content : Struct.TopContent
  , currentView : View
  , window : (Int, Int)
  , resizeBoxes : List (Int, Int)
  }

type View = ExplorerView | ImageView ListView.Model

initModel : Model
initModel = { path = ""
  , content = Struct.emptyTopContent
  , currentView = ExplorerView
  , window = (800, 600)
  , resizeBoxes = []
  }



-- UPDATE

mb = Signal.mailbox NoOp

type Action = UpdateContent Struct.TopContent
    | ChangePath String
    | ViewImages (List Struct.Image) Struct.Image
    | ForwardViewer ListView.Action
    | ExitListView
    | ChangeWindowSize (Int, Int)
    | ArrowPress (Int, Int)
    | NoOp

update : Action -> Model -> Model
update action model  =
  case action of
    UpdateContent content -> { model | content = content, resizeBoxes = content.sizes }
    ChangePath path -> { model | path = path }
    ViewImages list current ->
      { model |
        currentView = ImageView (ListView.initModel list current model.resizeBoxes model.window ) }
    ForwardViewer lvaction ->
      case model.currentView of
        ImageView lvmodel -> { model |
          currentView = ImageView (ListView.update lvaction lvmodel) }
        _ -> model
    ExitListView -> { model | currentView = ExplorerView }
    ChangeWindowSize dimensions ->
      case model.currentView of
        ImageView lvmodel -> { model |
          currentView = ImageView (ListView.update (ListView.ChangeWindowSize dimensions) lvmodel) }
        _ -> model
    ArrowPress dir -> case model.currentView of
        ImageView lvmodel -> case dir of
            (0,-1) -> update (ForwardViewer ListView.Next) model
            (0, 1) -> update (ForwardViewer ListView.Prev) model
            (-1, 0) -> update ExitListView model
            _ -> model
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
signalViewerToMain action =
  case action of
      ListView.Exit -> ExitListView
      _ -> ForwardViewer action


-- Retrieve content from server

httpAddress = Signal.forwardTo mb.address signalHttpToMain

signalHttpToMain : Struct.TopContent -> Action
signalHttpToMain content = UpdateContent content


port fetchString : Task.Task Http.Error ()
port fetchString = Task.andThen
  (Task.onError
    (Http.get Struct.topContentDecoder "gallery")
    (\msg -> Task.fail (Debug.log "Http.get error:" msg)))
  (Signal.send httpAddress)

-- Get window size

windowSignal = Signal.map signalWindowToMain Window.dimensions

signalWindowToMain dimensions = ChangeWindowSize dimensions


-- Handle Keyboard

keyboardSignal = Signal.map signalKeyboardToMain Keyboard.arrows

signalKeyboardToMain dir = ArrowPress (dir.x, dir.y)
