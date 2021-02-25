--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Session exposing (Session(..), encodeSession, getNavKey, getUser, sessionDecoder, signIn, signOut)

import Browser.Navigation as Nav
import Data.User exposing (User, userDecoder)
import Json.Decode exposing (Decoder, andThen, field, maybe, succeed)
import Json.Encode


type Session
    = Authed Nav.Key User
    | Guest Nav.Key


{-| get user from session
-}
getUser : Session -> Maybe User
getUser session =
    case session of
        Authed _ user ->
            Just user

        Guest _ ->
            Nothing


{-| Delete auth data from session
-}
signOut : Session -> Session
signOut session =
    Guest <| getNavKey session


{-| Set user into session (Set session to Authed)
-}
signIn : Session -> User -> Session
signIn session user =
    Authed (getNavKey session) user


{-| get nav key from session
-}
getNavKey : Session -> Nav.Key
getNavKey session =
    case session of
        Authed key _ ->
            key

        Guest key ->
            key



-- En/decoding


{-| Decodes a User entity from JSON and deserializes it into a User
-}
sessionDecoder : Nav.Key -> Decoder Session
sessionDecoder nav =
    maybe (field "user" userDecoder) |> andThen (sessionDecoderWrapper nav)


{-| Make session type from user value
-}
sessionDecoderWrapper : Nav.Key -> Maybe User -> Decoder Session
sessionDecoderWrapper nav user =
    case user of
        Just u ->
            succeed <| Authed nav u

        Nothing ->
            succeed <| Guest nav


{-| Encode session object
-}
encodeSession : Session -> Json.Encode.Value
encodeSession session =
    case session of
        Authed _ user ->
            Json.Encode.object [ ( "user", Data.User.encodeUser user ) ]

        Guest _ ->
            Json.Encode.object []
