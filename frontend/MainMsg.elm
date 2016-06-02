module MainMsg exposing (Msg(..))

import Explorer
import Viewer
import Struct
import Http


type Msg
    = MsgExplorer Explorer.Msg
    | MsgViewer Viewer.Msg
    | FetchContentSucceed Struct.TopContent
    | FetchContentFailed Http.Error
    | NoOp
