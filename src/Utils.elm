--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Utils exposing (..)

import DateFormat
import Time exposing (Posix, Zone)
import Http


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

{-| Format an HTTP error as a string
-}

fmtHttpError : Http.Error -> String
fmtHttpError error =
    case error of
        Http.BadUrl url ->
            "The URL " ++ url ++ " was invalid"

        Http.Timeout ->
            "Unable to reach the server, try again"

        Http.NetworkError ->
            "Unable to reach the server, check your network connection"

        Http.BadStatus 500 ->
            "The server had a problem, try again later"

        Http.BadStatus 400 ->
            "Verify your information and try again"

        Http.BadStatus _ ->
            "Unknown error"

        Http.BadBody errorMessage ->
            errorMessage
