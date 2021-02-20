--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>
-- TODO: replace with main


module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Data.Auth exposing (Authorization)
import Data.User as User
import Html
import Html.Styled exposing (..)
import Http
import Pages.Chat as Chat
import Pages.NotFound as PageNotFound
import Pages.SignIn as SignIn
import Request.Auth as ApiAuth
import Route exposing (Route)
import Session exposing (Session)
import Url exposing (Url)



-- Model


type PageView
    = ChatView Chat.Model
    | SignInView SignIn.Model
    | NotFound
    | Redirect Url


type alias Model =
    { session : Session
    , view : PageView
    }



-- init


init : Url -> Nav.Key -> ( Model, Cmd Msg )
init url key =
    ( { session = Session.Guest key
      , view = Redirect url
      }
    , ApiAuth.authed AuthedResult
    )



-- Update


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | AuthedResult (Result Http.Error Authorization)
    | FromChat Chat.Msg
    | FromSignIn SignIn.Msg



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    -- Match both message and view
    case ( msg, model.view ) of
        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.routeFromUrl url) model

        ( ClickedLink request, _ ) ->
            case request of
                Browser.Internal url ->
                    case url.fragment of
                        Nothing ->
                            -- Nothing to do
                            ( model, Cmd.none )

                        Just _ ->
                            ( model
                            , Nav.pushUrl (Session.getNavKey model.session) (Url.toString url)
                            )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( AuthedResult authRes, _ ) ->
            case authRes of
                Ok authorization ->
                    -- Go to chat; set authorized
                    tryGoToChat { model | session = Session.signIn model.session <| User.fromAuthorization authorization }

                Err _ ->
                    -- Go to sign in
                    goToSignIn model

        ( FromChat submsg, ChatView submodel ) ->
            -- Call chat update and pipe to model update
            let
                newState =
                    Chat.update submsg submodel
            in
            ( { model | view = ChatView <| Tuple.first newState }
            , Cmd.map FromChat <| Tuple.second newState
            )

        ( FromSignIn submsg, SignInView submodel ) ->
            -- Call chat update and pipe to model update
            let
                newState =
                    SignIn.update submsg submodel
            in
            ( { model | view = SignInView <| Tuple.first newState }
            , Cmd.map FromSignIn <| Tuple.second newState
            )

        ( _, _ ) ->
            -- Ignore message with incoherent view
            ( model, Cmd.none )



-- View


view : Model -> Browser.Document Msg
view model =
    let
        viewPage toMsg docname viewGetter =
            let
                { title, body } =
                    makeBrowserDocument docname viewGetter
            in
            { title = title
            , body = List.map (Html.map toMsg) body
            }
    in
    -- View different page based on current view
    case model.view of
        Redirect _ ->
            makeBrowserDocument "Elm-chat" viewBlank

        NotFound ->
            makeBrowserDocument "404 - Not found" PageNotFound.view

        ChatView submodel ->
            viewPage FromChat "Elm-chat" (Chat.view submodel)

        SignInView submodel ->
            viewPage FromSignIn "Elm-chat - Sign in" (SignIn.view submodel)


{-| Make browser document from title and Html
-}
makeBrowserDocument : String -> Html msg -> Document msg
makeBrowserDocument title body =
    { title = title
    , body = [ Html.Styled.toUnstyled body ]
    }


{-| View blank page
-}
viewBlank : Html Msg
viewBlank =
    div [] []



-- Functions


{-| Change page location
-}
changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    case maybeRoute of
        Nothing ->
            ( { model | view = NotFound }, Cmd.none )

        Just Route.Chat ->
            -- Must be authed
            tryGoToChat model

        Just Route.SignIn ->
            goToSignIn model


{-| Go to sign in page
-}
goToSignIn : Model -> ( Model, Cmd Msg )
goToSignIn model =
    let
        signInResult =
            SignIn.init model.session
    in
    ( { model | view = SignInView <| Tuple.first signInResult }
    , Cmd.map FromSignIn <| Tuple.second signInResult
    )


{-| Try (which means if user is set), to go to chat page;
otherwise go to sign in
-}
tryGoToChat : Model -> ( Model, Cmd Msg )
tryGoToChat model =
    case Session.getUser model.session of
        Just user ->
            let
                chatResult =
                    Chat.init model.session user
            in
            ( { model | view = ChatView <| Tuple.first chatResult }
            , Cmd.map FromChat <| Tuple.second chatResult
            )

        Nothing ->
            goToSignIn model
