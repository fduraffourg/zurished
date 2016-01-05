import ListView
import StartApp.Simple exposing (start)
import Keyboard

main =
  start
    { model = ListView.init ["1.jpg", "2.jpg", "3.jpg"]
    , update = ListView.update
    , view = ListView.view
    }
