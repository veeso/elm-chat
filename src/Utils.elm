--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Utils exposing (..)

import DateFormat
import Http
import Regex
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


{-| Check whether a Maybe is Just

    isJust (Maybe "foo") -> True
    isJust Nothing -> False

-}
isJust : Maybe a -> Bool
isJust m =
    case m of
        Just _ ->
            True

        Nothing ->
            False


{-| Check whether a Maybe is Nothing

    isNothing Nothing -> True
    isNothing (Maybe "foo") -> False

-}
isNothing : Maybe a -> Bool
isNothing m =
    case m of
        Just _ ->
            False

        Nothing ->
            True


{-| Check whether a string is alphanumerical

    isAlphanumerical "pippo97" -> True
    isAlphanumerical "mon-a" -> False

-}
isAlphanumerical : String -> Bool
isAlphanumerical check =
    Regex.contains (Maybe.withDefault Regex.never <| Regex.fromString "^[a-zA-Z0-9]+$") check

isPasswordSafe : String -> Bool
isPasswordSafe password =
    