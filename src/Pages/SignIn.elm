--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Pages.SignIn exposing (..)

import Css exposing (..)
import Data.Jwt exposing (Jwt)
import File exposing (File)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, placeholder, value)
import Html.Styled.Events exposing (onFocus)
import Http
import Request.Auth as ApiAuth
import Utils exposing (fmtHttpError, isJust)
import Views.Alert as Alert
import Views.Topbar as Topbar



-- Model --


{-| UserCredentials describes the credentials used to sign in
-}
type alias UserCredentials =
    { username : String
    , password : String
    }


{-| SignUpData describes the data used to sign up into the application
-}
type alias SignUpData =
    { username : String
    , password : String
    , pretype : String
    , avatar : Maybe File
    }


{-| FocusHolder describes the text input field which is currently holding the focus
-}
type FocusHolder
    = LoginUsername
    | LoginPassword
    | RegUsername
    | RegPassword
    | RegPasswordRetype


type alias Model =
    { credentials : UserCredentials
    , signUpForm : SignUpData
    , focus : FocusHolder
    , error : Maybe String
    }



-- Update --


type Msg
    = InputChanged String
    | FocusChanged FocusHolder
    | SignIn
    | SignUp
    | GotAuthResult (Result Http.Error Jwt)
    | Error String
    | ErrorDismissed


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputChanged txt ->
            ( updateText model txt, Cmd.none )

        FocusChanged focus ->
            ( { model | focus = focus }, Cmd.none )

        SignIn ->
            -- TODO: validate forms
            ( model, ApiAuth.signin model.credentials.username model.credentials.password GotAuthResult )

        SignUp ->
            -- TODO: validate forms
            ( model, ApiAuth.signup model.signUpForm.username model.signUpForm.password model.signUpForm.avatar GotAuthResult )

        GotAuthResult result ->
            case result of
                Ok _ ->
                    -- TODO: do something
                    ( model, Cmd.none )

                Err err ->
                    -- TODO: format error with sense
                    ( { model | error = Just "error!" }, Cmd.none )

        Error errmsg ->
            ( { model | error = Just errmsg }, Cmd.none )

        ErrorDismissed ->
            ( { model | error = Nothing }, Cmd.none )


updateText : Model -> String -> Model
updateText model txt =
    case model.focus of
        LoginPassword ->
            { model | credentials = asUserPasswordIn model.credentials txt }

        LoginUsername ->
            { model | credentials = asUserUsernameIn model.credentials txt }

        RegUsername ->
            { model | signUpForm = asRegUsernameIn model.signUpForm txt }

        RegPassword ->
            { model | signUpForm = asRegPasswordIn model.signUpForm txt }

        RegPasswordRetype ->
            { model | signUpForm = asRegPasswordRetypeIn model.signUpForm txt }


{-| Helper to update nested records
asPasswordIn updates the password inside a UserCredentials record
-}
asUserPasswordIn : UserCredentials -> String -> UserCredentials
asUserPasswordIn credentials password =
    { credentials | password = password }


{-| Helper to update nested records
asPasswordIn updates the username inside a UserCredentials record
-}
asUserUsernameIn : UserCredentials -> String -> UserCredentials
asUserUsernameIn credentials username =
    { credentials | username = username }


{-| Helper to update nested records
asRegUsernameIn updates the username inside a SignUpData record
-}
asRegUsernameIn : SignUpData -> String -> SignUpData
asRegUsernameIn data username =
    { data | username = username }


{-| Helper to update nested records
asRegUsernameIn updates the password inside a SignUpData record
-}
asRegPasswordIn : SignUpData -> String -> SignUpData
asRegPasswordIn data password =
    { data | password = password }


{-| Helper to update nested records
asRegUsernameIn updates the password retype inside a SignUpData record
-}
asRegPasswordRetypeIn : SignUpData -> String -> SignUpData
asRegPasswordRetypeIn data password =
    { data | pretype = password }
