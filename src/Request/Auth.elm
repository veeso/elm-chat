--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Request.Auth exposing (authed, signin, signout, signup)

import Data.Auth exposing (Authorization, authDecoder)
import File exposing (File)
import Http exposing (emptyBody, filePart, multipartBody, stringPart)
import Json.Encode as Encode


{-| Send a POST request to sign in
-}
signin : String -> String -> (Result Http.Error Authorization -> msg) -> Cmd msg
signin username password msg =
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
        , expect = Http.expectJson msg authDecoder
        }


{-| Send a POST request to sign up
-}
signup : String -> String -> Maybe File -> (Result Http.Error Authorization -> msg) -> Cmd msg
signup username password avatar msg =
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
            multipartBody
                ((stringPart "data" <| Encode.encode 0 user)
                    :: (case avatar of
                            Just file ->
                                [ filePart "avatar" file ]

                            Nothing ->
                                []
                       )
                )
        , expect = Http.expectJson msg authDecoder
        }


{-| Send a GET request to check whether the user is authed
-}
authed : (Result Http.Error Authorization -> msg) -> Cmd msg
authed msg =
    Http.get
        { url = ":3000/api/auth/authed"
        , expect = Http.expectJson msg authDecoder
        }


{-| Send a POST request to sign out
-}
signout : (Result Http.Error () -> msg) -> Cmd msg
signout msg =
    Http.post
        { url = ":3000/api/auth/signOut"
        , body = emptyBody
        , expect = Http.expectWhatever msg
        }
