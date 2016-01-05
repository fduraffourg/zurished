import ListView
import Keyboard
import Signal
import Window


initState = ListView.init ["1.jpg", "2.jpg", "3.jpg"]

main = Signal.map2 (ListView.view address) Window.dimensions mainState

mainState : Signal ListView.Model
mainState = Signal.foldp ListView.update initState input


-- INPUT

messages : Signal.Mailbox ListView.Action
messages = Signal.mailbox ListView.NoOp
address = messages.address

keyboardToAction : { x:Int, y:Int } -> ListView.Action
keyboardToAction {x,y} =
  case x of
    -1 -> ListView.Prev
    1 -> ListView.Next
    _ -> ListView.NoOp

keyboardInput = Signal.map keyboardToAction Keyboard.arrows

input : Signal.Signal ListView.Action
input = Signal.merge keyboardInput messages.signal
