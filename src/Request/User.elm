--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Request.User exposing (Msg, signin)

import Data.Jwt exposing (Jwt, jwtDecoder)
import Http
import Json.Decode exposing (Decoder, andThen, field, string)
import Json.Encode as Encode


type Msg
    = SignedIn (Result Http.Error Jwt)


{-| Send a POST request to sign in
-}
signin : String -> String -> Cmd Msg
signin username password =
    let
        user =
            Encode.object
                [ ( "username", Encode.string username )
                , ( "secret", Encode.string password )
                ]
    in
    Http.post
        { url = ":3000/api/auth/signIn"
        , body = Http.jsonBody user
        , expect = Http.expectJson SignedIn (authTokenDecoder |> andThen jwtDecoder)
        }



-- Deserializers


authTokenDecoder : Decoder String
authTokenDecoder =
    field "data" string
