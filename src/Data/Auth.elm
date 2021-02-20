--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.Auth exposing (Authorization, authDecoder)

import Json.Decode exposing (Decoder, field, map, string)


{-| Authorization contains the authorization object, which contains data
about the current client

    - username : String: current username

-}
type alias Authorization =
    { username : String }


{-| Decodes an authorization object from JSON
-}
authDecoder : Decoder Authorization
authDecoder =
    map Authorization
        (field "username" string)
