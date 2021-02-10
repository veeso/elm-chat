--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.Jwt exposing (Jwt, jwtDecoder)

import Json.Decode exposing (Decoder, fail, field, int, map3, string, succeed)
import Jwt exposing (decodeToken, errorToString)


{-| Jwt contains the parameters contained in the JWT

    - username : String: current username

-}
type alias Jwt =
    { iat : Int
    , exp : Int
    , username : String
    }


{-| Decodes a JWT entity from JSON and deserializes it into a User
Then converts the JWT into a Jwt structure
-}
jwtDecoder : String -> Decoder Jwt
jwtDecoder token =
    case decodeToken jwtJsonDecoder token of
        Ok jwt ->
            succeed jwt

        Err err ->
            fail (errorToString err)


jwtJsonDecoder : Decoder Jwt
jwtJsonDecoder =
    map3 Jwt
        (field "iat" int)
        (field "exp" int)
        (field "username" string)
