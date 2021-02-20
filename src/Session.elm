--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Session exposing (Session(..), getNavKey, getUser, signIn, signOut)

import Browser.Navigation as Nav
import Data.User exposing (User)


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
