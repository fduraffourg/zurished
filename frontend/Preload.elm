module Preload exposing (Model, initModel, Msg(..), updateLoaded, updateGoNext, updateGoPrev, list)

import Array exposing (Array)
import Basics
import Struct exposing (Image)
import Html exposing (Html, img, div)
import Html.Attributes exposing (src)


-- Maximum number of medias to preload


maxNumPreload =
    10


type alias Model =
    { next :
        Int
        -- Index of next image
    , position :
        Int
        -- Index of next image to preload
    , direction :
        Direction
        -- Direction of viewing
    , uniDirCnt :
        Int
        -- Indicator of how many image to preload
    }


type Direction
    = Forward
    | Backward


initModel : Array Image -> Int -> Model
initModel list position =
    { next = position + 1
    , position = position + 1
    , direction = Forward
    , uniDirCnt = 0
    }


type Msg
    = Load


updateLoaded : Model -> Model
updateLoaded model =
    case model.direction of
        Forward ->
            { model | position = model.position + 1 }

        Backward ->
            { model | position = model.position - 1 }


updateGoNext : Model -> Model
updateGoNext model =
    let
        uniDirCnt =
            model.uniDirCnt + 1
    in
        case model.direction of
            Forward ->
                { model
                    | position = model.position + 1
                    , uniDirCnt = uniDirCnt
                    , next = model.next + 1
                }

            Backward ->
                { model
                    | direction = Forward
                    , position = model.next + 3
                    , next = model.next + 3
                    , uniDirCnt = uniDirCnt
                }


updateGoPrev : Model -> Model
updateGoPrev model =
    let
        uniDirCnt =
            model.uniDirCnt - 1
    in
        case model.direction of
            Forward ->
                { model
                    | direction = Backward
                    , position = model.next - 3
                    , next = model.next - 3
                    , uniDirCnt = uniDirCnt
                }

            Backward ->
                { model
                    | position = model.position - 1
                    , next = model.next - 1
                    , uniDirCnt = uniDirCnt
                }


list : Model -> Array a -> ( Array a, Maybe a )
list model medias =
    let
        goingBack =
            (model.direction == Forward && model.uniDirCnt < 0)
                || (model.direction == Backward && model.uniDirCnt > 0)
    in
        if goingBack then
            -- We are going back to medias that were alread shown, so we don't need
            -- to preload anything.
            ( Array.slice model.next (model.next + 1) medias, Nothing )
        else
            let
                preloadCount =
                    Basics.min maxNumPreload
                        (Basics.abs model.uniDirCnt)
            in
                let
                    preloaded =
                        if model.position >= model.next then
                            Array.slice model.next model.position medias
                        else
                            Array.slice (Basics.max 0 (model.position + 1))
                                (model.next + 1)
                                medias

                    toPreload =
                        if Basics.abs (model.position - model.next) > preloadCount then
                            Nothing
                        else
                            Array.get model.position medias
                in
                    ( preloaded, toPreload )
