--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.User exposing (User, addUser, fromAuthorization, sortUsers, updateUserStatus, userDecoder, usersDecoder)

-- Dependencies

import Data.Auth
import Iso8601
import Json.Decode exposing (Decoder, bool, field, list, map4, maybe, string)
import Time exposing (Posix)


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
    , lastActivity : Posix
    , online : Bool
    }



-- Manipulation


{-| Add a user to users list and then sort them by username

    addUser [b, c] a  -> [a, b, c]

-}
addUser : List User -> User -> List User
addUser users user =
    sortUsers (user :: users)


{-| Sort users by username

    sortUsers [c, a, b] -> [a, b, c]

-}
sortUsers : List User -> List User
sortUsers users =
    List.sortBy .username users


{-| Update the status the provided username

    updateUserStatus [...] "omar" False Posix

-}
updateUserStatus : List User -> String -> Bool -> Posix -> List User
updateUserStatus users username online lastActivity =
    case users of
        [] ->
            []

        first :: more ->
            (if first.username == username then
                { first | online = online, lastActivity = lastActivity }

             else
                first
            )
                :: updateUserStatus more username online lastActivity



-- Builder


{-| Make user from authorization
-}
fromAuthorization : Data.Auth.Authorization -> User
fromAuthorization auth =
    { username = auth.username
    , avatar = auth.avatar
    , lastActivity = Time.millisToPosix 0
    , online = True
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
        (field "lastActivity" Iso8601.decoder)
        (field "online" bool)
