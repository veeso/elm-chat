--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Request.Auth exposing (Msg, authed, signin, signout, signup)

import Data.Jwt exposing (Jwt, jwtDecoder)
import File exposing (File)
import Http exposing (emptyBody, filePart, multipartBody, stringPart)
import Json.Decode exposing (Decoder, andThen, field, string)
import Json.Encode as Encode


type Msg
    = SignedIn (Result Http.Error Jwt)
    | Authed (Result Http.Error ())
    | SignedOut (Result Http.Error ())


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


{-| Send a POST request to sign up
-}
signup : String -> String -> Maybe File -> Cmd Msg
signup username password avatar =
    let
        user =
            Encode.object
                [ ( "username", Encode.string username )
                , ( "secret", Encode.string password )
                ]
    in
    Http.post
        { url = ":3000/api/auth/signUp"
        , body =
            case avatar of
                Just file ->
                    multipartBody
                        [ stringPart "data" <| Encode.encode 0 user
                        , filePart "avatar" file
                        ]

                Nothing ->
                    multipartBody [ stringPart "data" <| Encode.encode 0 user ]
        , expect = Http.expectJson SignedIn (authTokenDecoder |> andThen jwtDecoder)
        }


{-| Send a GET request to check whether the user is authed
-}
authed : Cmd Msg
authed =
    Http.get
        { url = " :3000/api/auth/authed"
        , expect = Http.expectWhatever Authed
        }


{-| Send a POST request to sign out
-}
signout : Cmd Msg
signout =
    Http.post
        { url = ":3000/api/auth/signOut"
        , body = emptyBody
        , expect = Http.expectWhatever SignedOut
        }



-- Deserializers


authTokenDecoder : Decoder String
authTokenDecoder =
    field "data" string
