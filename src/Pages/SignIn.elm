--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Pages.SignIn exposing (..)

import Css exposing (..)
import Data.Auth exposing (Authorization)
import File exposing (File)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attributes exposing (class, css, for, id, type_, value)
import Html.Styled.Events exposing (on, onClick, onFocus, onInput)
import Http
import Request.Auth as ApiAuth
import Route
import Session exposing (Session)
import Utils exposing (fmtHttpError, getFilesFromInput, isAlphanumerical, isPasswordSafe)
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
    { session : Session
    , credentials : UserCredentials
    , signUpForm : SignUpData
    , focus : FocusHolder
    , error : Maybe String
    }



-- Init


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , credentials =
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
    | AvatarUploaded (List File)
    | SignIn
    | SignUp
    | GotAuthResult (Result Http.Error Authorization)
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

        AvatarUploaded files ->
            -- Get head of files and put it into the model
            ( { model | signUpForm = asRegAvatarIn model.signUpForm <| List.head files }, Cmd.none )

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
                    -- Go to chat page
                    ( model, Route.replaceUrl (Session.getNavKey model.session) Route.Chat )

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
asRegPasswordIn updates the password inside a SignUpData record
-}
asRegPasswordIn : SignUpData -> String -> SignUpData
asRegPasswordIn data password =
    { data | password = password }


{-| Helper to update nested records
asRegPasswordRetypeIn updates the password retype inside a SignUpData record
-}
asRegPasswordRetypeIn : SignUpData -> String -> SignUpData
asRegPasswordRetypeIn data password =
    { data | pretype = password }


{-| Helper to update nested records
asRegAvatarIn updates avatar inside a SignUpData record
-}
asRegAvatarIn : SignUpData -> Maybe File -> SignUpData
asRegAvatarIn data file =
    { data | avatar = file }



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
    -- Check if passwords matches
    if
        data.password == data.pretype
    then
        Ok ()

    else
        Err "Passwords don't match"



-- View


view : Model -> Html Msg
view model =
    div []
        [ viewTopbar
        , div [ class "container-fluid" ]
            [ viewErrorMessage model.error
            , div [ class "row" ]
                [ viewSigninForm model.credentials
                , viewSignupForm model.signUpForm
                ]
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


{-| View signin form wrapper
-}
viewSigninForm : UserCredentials -> Html Msg
viewSigninForm credentials =
    div [ class "col-6" ]
        [ viewFormHeader "Sign in"
        , div [ class "row" ]
            [ div
                [ class "col-12"
                , class "d-flex"
                , class "align-content-center"
                , class "justify-content-center"
                , css [ padding (Css.em 2) ]
                ]
                [ form [ class "col-6" ]
                    [ viewSigninUsername credentials.username
                    , viewSigninPassword credentials.password
                    , viewSubmitBtn "Sign In!" SignIn
                    ]
                ]
            ]
        ]


{-| View signup form wrapper
-}
viewSignupForm : SignUpData -> Html Msg
viewSignupForm data =
    div [ class "col-6" ]
        [ viewFormHeader "Sign up"
        , div [ class "row" ]
            [ div
                [ class "col-12"
                , class "d-flex"
                , class "align-content-center"
                , class "justify-content-center"
                , css [ padding (Css.em 2) ]
                ]
                [ form [ class "col-6" ]
                    [ viewSignupUsername data.username
                    , viewSignupPassword data.password
                    , viewSignupPasswordRetype data.pretype
                    , viewSignupAvatar
                    , viewSubmitBtn "Sign Up!" SignUp
                    ]
                ]
            ]
        ]


{-| View form header
-}
viewFormHeader : String -> Html Msg
viewFormHeader title =
    div [ class "row" ]
        [ div
            [ class "col-12"
            , class "d-flex"
            , class "align-content-center"
            , class "justify-content-center"
            , css [ padding (Css.em 2) ]
            ]
            [ h3 [] [ text title ]
            ]
        ]


{-| View sign in username field
-}
viewSigninUsername : String -> Html Msg
viewSigninUsername username =
    div [ class "mb-3" ]
        [ label [ for "signinUsername", class "form-label" ]
            [ text "Username "
            , i [ css [ color (hex "#ff0000") ] ] [ text "*" ]
            ]
        , input
            [ id "signinUsername"
            , class "form-control"
            , onFocus (FocusChanged LoginUsername)
            , onInput InputChanged
            , value username
            , Attributes.required True
            ]
            []
        ]


{-| View sign in password field
-}
viewSigninPassword : String -> Html Msg
viewSigninPassword password =
    div [ class "mb-3" ]
        [ label [ for "signinPassword", class "form-label" ]
            [ text "Password "
            , i [ css [ color (hex "#ff0000") ] ] [ text "*" ]
            ]
        , input
            [ id "signinPassword"
            , class "form-control"
            , type_ "password"
            , onFocus (FocusChanged LoginPassword)
            , onInput InputChanged
            , value password
            , Attributes.required True
            ]
            []
        ]


{-| View sign up username field
-}
viewSignupUsername : String -> Html Msg
viewSignupUsername username =
    div [ class "mb-3" ]
        [ label [ for "signupUsername", class "form-label" ]
            [ text "Username "
            , i [ css [ color (hex "#ff0000") ] ] [ text "*" ]
            ]
        , input
            [ id "signupUsername"
            , class "form-control"
            , onFocus (FocusChanged RegUsername)
            , onInput InputChanged
            , value username
            , Attributes.required True
            ]
            []
        , div
            [ class "form-text" ]
            [ text "Username must contain alphanumeric characters only." ]
        ]


{-| View sign up password field
-}
viewSignupPassword : String -> Html Msg
viewSignupPassword password =
    div [ class "mb-3" ]
        [ label [ for "signupPassword", class "form-label" ]
            [ text "Password "
            , i [ css [ color (hex "#ff0000") ] ] [ text "*" ]
            ]
        , input
            [ id "signupPassword"
            , class "form-control"
            , onFocus (FocusChanged RegPassword)
            , onInput InputChanged
            , value password
            , type_ "password"
            , Attributes.required True
            ]
            []
        , div
            [ class "form-text" ]
            [ text "Password must be at least 8 characters long." ]
        ]


{-| View sign up password retype field
-}
viewSignupPasswordRetype : String -> Html Msg
viewSignupPasswordRetype feedback =
    div [ class "mb-3" ]
        [ label [ for "signupPasswordRetype", class "form-label" ]
            [ text "Retype password "
            , i [ css [ color (hex "#ff0000") ] ] [ text "*" ]
            ]
        , input
            [ id "signupPasswordRetype"
            , class "form-control"
            , onFocus (FocusChanged RegPasswordRetype)
            , onInput InputChanged
            , value feedback
            , type_ "password"
            , Attributes.required True
            ]
            []
        ]


{-| View sign up avatar field
-}
viewSignupAvatar : Html Msg
viewSignupAvatar =
    div [ class "mb-3" ]
        [ label [ for "signupAvatar", class "form-label" ]
            [ text "Upload your avatar" ]
        , input
            [ type_ "file"
            , id "signupAvatar"
            , class "form-control"
            , on "change" (getFilesFromInput AvatarUploaded)
            ]
            []
        ]


{-| View submit button
-}
viewSubmitBtn : String -> Msg -> Html Msg
viewSubmitBtn btntxt message =
    button
        [ type_ "button"
        , class "btn"
        , class "btn-primary"
        , onClick message
        ]
        [ text btntxt ]
