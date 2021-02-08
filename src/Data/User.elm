--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.User exposing (..)

-- Dependencies

import Date
import Html exposing (dt)
import Json.Decode exposing (Decoder, andThen, bool, fail, field, list, map4, maybe, string, succeed)


{-| User describes a user registered in the chat application,
obviously without its confidentials parameters.

    - username : String: username, unique identifier
    - avatar : Maybe String: optional uri to avatar
    - lastActivity : Date.Date: last activity for the user
    - online : Bool: True if user is online

-}
type alias User =
    { username : String
    , avatar : Maybe String
    , lastActivity : Date.Date
    , online : Bool
    }



-- Deserialization


{-| Decodes a JSON list of users into an Elm list of User
-}
usersDecoder : Decoder (List User)
usersDecoder =
    list userDecoder


{-| Decodes a User entity from JSON and deserializes it into a User
-}
userDecoder : Decoder User
userDecoder =
    map4 User
        (field "username" string)
        (maybe (field "avatar" string))
        (field "lastActivity" string |> andThen lastActivityDecoder)
        (field "online" bool)


{-| Custom decoder for last activity parameter
-}
lastActivityDecoder : String -> Decoder Date.Date
lastActivityDecoder isodate =
    case Date.fromIsoString isodate of
        Ok dt ->
            succeed dt

        Err err ->
            fail ("Could not parse 'lastActivity': " ++ err)
