--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Main exposing (main)

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


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { session = Session.Guest key
      , view = Redirect url
      }
    , ApiAuth.authed AuthedResult
    )



-- Update


type Msg
    = UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | AuthedResult (Result Http.Error Authorization)
    | FromChat Chat.Msg
    | FromSignIn SignIn.Msg



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    -- Match both message and view
    case ( msg, model.view ) of
        ( UrlChanged url, _ ) ->
            changeRouteTo (Route.routeFromUrl url) model

        ( LinkClicked request, _ ) ->
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
                    -- Go to home
                    ( { model | session = Session.signIn model.session <| User.fromAuthorization authorization }
                    , Route.replaceUrl (Session.getNavKey model.session) Route.Chat
                    )

                Err _ ->
                    -- Go to sign in
                    goToSignIn model

        ( FromChat submsg, ChatView submodel ) ->
            -- Call chat update and pipe to model update
            let
                newState =
                    Chat.update submsg submodel
            in
            -- Update submodel and session
            ( updateSubmodelAndSession model (Tuple.first newState).session (ChatView <| Tuple.first newState)
            , Cmd.map FromChat <| Tuple.second newState
            )

        ( FromSignIn submsg, SignInView submodel ) ->
            -- Call chat update and pipe to model update
            let
                newState =
                    SignIn.update submsg submodel
            in
            -- Update submodel and session
            ( updateSubmodelAndSession model (Tuple.first newState).session (SignInView <| Tuple.first newState)
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- Functions


{-| Update model's submodel and session
-}
updateSubmodelAndSession : Model -> Session -> PageView -> Model
updateSubmodelAndSession initModel session newView =
    { initModel | view = newView, session = session }


{-| Change page location
-}
changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    case maybeRoute of
        Nothing ->
            ( { model | view = NotFound }, Cmd.none )

        Just Route.Root ->
            -- Go to chat or sign in
            case Session.getUser model.session of
                Just _ ->
                    -- Authed; replace url and go to chat
                    ( model, Route.replaceUrl (Session.getNavKey model.session) Route.Chat )

                Nothing ->
                    -- Go to sign in
                    ( model, Route.replaceUrl (Session.getNavKey model.session) Route.SignIn )

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



-- Main


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
