--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.Jwt exposing (Jwt, jwtDecoder)

import Json.Decode exposing (Decoder, field, int, map3, string)
import Jwt exposing (JwtError, decodeToken)


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
jwtDecoder : String -> Result JwtError Jwt
jwtDecoder token =
    decodeToken jwtJsonDecoder token


jwtJsonDecoder : Decoder Jwt
jwtJsonDecoder =
    map3 Jwt
        (field "iat" int)
        (field "exp" int)
        (field "username" string)
