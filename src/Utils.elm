--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Utils exposing (..)

import DateFormat
import Time exposing (Posix, Zone)


{-| Format a date with syntax => 2021/02/13 15:49
-}
prettyDateFormatter : Zone -> Posix -> String
prettyDateFormatter =
    DateFormat.format
        [ DateFormat.yearNumberLastTwo
        , DateFormat.text "/"
        , DateFormat.monthFixed
        , DateFormat.text "/"
        , DateFormat.dayOfMonthFixed
        , DateFormat.text " "
        , DateFormat.hourFixed
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]
