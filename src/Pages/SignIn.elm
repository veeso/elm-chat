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
import Utils exposing (fmtHttpError, isAlphanumerical, isJust, isPasswordSafe)
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



-- Init


init : ( Model, Cmd Msg )
init =
    ( { credentials =
            { username = ""
            , password = ""
            }
      , signUpForm =
            { username = ""
            , password = ""
            , pretype = ""
            , avatar = Nothing
            }
      , focus = LoginUsername
      , error = Nothing
      }
    , Cmd.none
    )



-- Update --


type Msg
    = InputChanged String
    | FocusChanged FocusHolder
    | SignIn
    | SignUp
    | GotAuthResult (Result Http.Error Jwt)
    | Error String
    | ErrorDismissed
    | NothingToDo


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputChanged txt ->
            ( updateText model txt, Cmd.none )

        FocusChanged focus ->
            ( { model | focus = focus }, Cmd.none )

        SignIn ->
            -- validate forms
            case validateSignInForm model.credentials of
                Ok _ ->
                    ( model, ApiAuth.signin model.credentials.username model.credentials.password GotAuthResult )

                Err errmsg ->
                    ( { model | error = Just errmsg }, Cmd.none )

        SignUp ->
            -- validate forms
            case validateSignUpForm model.signUpForm of
                Ok _ ->
                    ( model, ApiAuth.signup model.signUpForm.username model.signUpForm.password model.signUpForm.avatar GotAuthResult )

                Err errmsg ->
                    ( { model | error = Just errmsg }, Cmd.none )

        GotAuthResult result ->
            case result of
                Ok _ ->
                    -- TODO: do something
                    ( model, Cmd.none )

                Err err ->
                    -- format error with sense
                    ( { model | error = Just <| fmtAuthResponse err }, Cmd.none )

        Error errmsg ->
            ( { model | error = Just errmsg }, Cmd.none )

        ErrorDismissed ->
            ( { model | error = Nothing }, Cmd.none )

        NothingToDo ->
            ( model, Cmd.none )


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



-- Format


{-| Format http bad response got from authentication request
-}
fmtAuthResponse : Http.Error -> String
fmtAuthResponse err =
    fmtHttpError err
        (Just
            (\x ->
                case x of
                    401 ->
                        "Sorry, we couldn't find any user with that username and password"

                    409 ->
                        "Sorry, a user with that username already exists"

                    _ ->
                        "There was an error in trying to authenticate you. Please, retry later..."
            )
        )



-- Validators


{-| Check whether provided credentials are valid for sign in
In case of error returns the error message
-}
validateSignInForm : UserCredentials -> Result String ()
validateSignInForm credentials =
    -- Check if values are set
    if String.isEmpty credentials.username || String.isEmpty credentials.password then
        Err "Username and password are required"

    else
        Ok ()


{-| Check whether provided data for signin up are valid
In case of error returns the error message
-}
validateSignUpForm : SignUpData -> Result String ()
validateSignUpForm data =
    -- Check username first
    if String.isEmpty data.username || not (isAlphanumerical data.username) then
        Err "Invalid username: must contain only alphanumeric characters!"

    else
    -- Check password
    if
        not (isPasswordSafe data.password)
    then
        Err "Password is not valid: must be at least 8 characters long and contain at least one uppercase, one number and one special character"

    else
        Ok ()



-- View


view : Model -> Html Msg
view model =
    div []
        [ viewTopbar
        , div [ class "container-fluid" ]
            [ viewErrorMessage model.error
            ]
        ]


{-| View error message
-}
viewErrorMessage : Maybe String -> Html Msg
viewErrorMessage error =
    case error of
        Just message ->
            Alert.viewAlert message Alert.Error ErrorDismissed

        Nothing ->
            div [] []


{-| View topbar
-}
viewTopbar : Html Msg
viewTopbar =
    Topbar.viewTopbar { onSignOut = NothingToDo } False

-- TODO: other views
