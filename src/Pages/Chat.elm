--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Pages.Chat exposing (..)

import Css exposing (..)
import Data.Message as Messages
import Data.User exposing (User)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, placeholder, readonly, value)
import Html.Styled.Events exposing (onClick, onInput)
import Http
import Request.Auth as ApiAuth
import Request.Messages as ApiMessages
import Request.User as ApiUsers
import Route
import Session exposing (Session)
import Time
import Utils exposing (fmtHttpError, isJust, prettyDateFormatter)
import Views.Alert as Alert
import Views.Conversation as ConversationView
import Views.Topbar as Topbar
import Views.User as UserList



-- Model --


type alias Model =
    { session : Session
    , userInput : String
    , users : List User -- The list of users
    , selectedUser : Maybe User -- The user I've selected
    , client : User -- Who am I?
    , conversation : Messages.Conversation -- The conversation I'm having with selected user
    , error : Maybe String
    }



-- Init


init : Session -> User -> ( Model, Cmd Msg )
init session client =
    ( { session = session
      , userInput = ""
      , users = []
      , selectedUser = Nothing
      , client = client
      , conversation = []
      , error = Nothing
      }
    , ApiUsers.getUsers GotUsers
    )



-- Update --


type Msg
    = InputChanged String
    | MessageSubmit
    | UserSelected User
    | GotUsers (Result Http.Error (List User))
    | GotConversation (Result Http.Error Messages.Conversation)
    | MessageSent (Result Http.Error Messages.Message)
    | MarkedAsRead (Result Http.Error String)
    | SignOut
    | SignedOut (Result Http.Error ())
    | Error String
    | ErrorDismissed


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputChanged newMsg ->
            -- Update message box
            ( { model | userInput = newMsg }, Cmd.none )

        MessageSubmit ->
            -- Send message
            ( { model | userInput = "" }
            , case model.selectedUser of
                Just selectedUser ->
                    ApiMessages.sendMessage selectedUser.username model.userInput MessageSent

                Nothing ->
                    -- Can't send message if no user is selecetd NOTE: this should never happen
                    Cmd.none
            )

        UserSelected user ->
            ( { model | selectedUser = Just user, conversation = [] }, Cmd.none )

        GotUsers result ->
            case result of
                Ok users ->
                    ( { model | users = users }, Cmd.none )

                -- Set users
                Err err ->
                    update (Error (fmtHttpError err Nothing)) model

        GotConversation result ->
            case result of
                -- Set conversation; notify to server messages have been read NOTE: we don't mark conversation as read HERE, because we do later for each message in `MarkedAsRead`
                Ok conversation ->
                    ( { model | conversation = conversation }, Cmd.batch (notifyMessageRead conversation model.client.username) )

                Err err ->
                    update (Error (fmtHttpError err Nothing)) model

        MessageSent result ->
            case result of
                Ok chatmsg ->
                    ( { model | conversation = Messages.pushMessage model.conversation chatmsg }, Cmd.none )

                Err err ->
                    update (Error (fmtHttpError err Nothing)) model

        MarkedAsRead result ->
            case result of
                Ok msgid ->
                    ( { model | conversation = Messages.markMessageAsRead model.conversation msgid }, Cmd.none )

                Err err ->
                    update (Error (fmtHttpError err Nothing)) model

        SignOut ->
            ( model, ApiAuth.signout SignedOut )

        SignedOut result ->
            case result of
                Ok _ ->
                    -- go to sign in somehow
                    ( model, Route.replaceUrl (Session.getNavKey model.session) Route.SignIn )

                Err err ->
                    update (Error (fmtHttpError err Nothing)) model

        Error err ->
            ( { model | error = Just err }, Cmd.none )

        ErrorDismissed ->
            ( { model | error = Nothing }, Cmd.none )


{-| Mark all messages sent to us as read and notify remote

    notifyMessageRead [ a, b ] foo

-}
notifyMessageRead : Messages.Conversation -> String -> List (Cmd Msg)
notifyMessageRead conversation username =
    case conversation of
        [] ->
            []

        first :: more ->
            (if first.recipient == username then
                ApiMessages.markAsRead username MarkedAsRead

             else
                Cmd.none
            )
                :: notifyMessageRead more username



-- View


view : Model -> Html Msg
view model =
    div []
        [ viewTopbar
        , div [ class "container-fluid" ]
            [ viewHeader model
            , viewErrorMessage model.error
            , viewChatBody model
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
    Topbar.viewTopbar { onSignOut = SignOut } True


{-| View chat header
-}
viewHeader : Model -> Html Msg
viewHeader model =
    div
        [ class "row"
        , class "justify-content-end"
        , css
            [ position relative
            , borderBottom3 (px 1) solid (hex "#cccccc")
            , backgroundColor (hex "#ededed")
            , padding (px 16)
            ]
        ]
        [ div [ class "col-4" ] [ UserList.viewAvatar model.client.avatar ]
        , div [ class "col-8" ] [ viewOtherUserInHeader model.selectedUser ]
        ]


{-| View the selected user info in the header
-}
viewOtherUserInHeader : Maybe User -> Html Msg
viewOtherUserInHeader selectedUser =
    case selectedUser of
        Just user ->
            div
                [ class "row"
                , class "align-items-center"
                ]
                [ UserList.viewAvatarAndStatus user.avatar user.online
                , viewOtherUserUsername user.username
                , viewOtherUserLastActivity user.lastActivity
                ]

        Nothing ->
            div [] []


{-| View the selected user last activity in the header
-}
viewOtherUserUsername : String -> Html Msg
viewOtherUserUsername username =
    div [ class "col-4" ] [ h6 [] [ text username ] ]


{-| View the selected user last activity in the header
-}
viewOtherUserLastActivity : Time.Posix -> Html Msg
viewOtherUserLastActivity lastActivity =
    div [ class "col", class "algin-self-end", class "justify-content-end", css [ textAlign end ] ]
        [ span [ css [ color (hex "#aaaaaa") ] ] [ text (prettyDateFormatter Time.utc lastActivity) ]
        ]


{-| View the chat body (main body of the chat; users + messages)
-}
viewChatBody : Model -> Html Msg
viewChatBody model =
    div [ class "row" ]
        [ div [ class "col-4", css [ overflow auto ] ]
            [ viewUserList model.users model.selectedUser
            ]
        , div [ class "col-8", css [ borderLeft3 (px 1) solid (hex "#cccccc"), overflow auto ] ]
            [ ConversationView.viewConversation model.conversation model.client.username
            ]
        ]


{-| View user list; selected user is rendered differently

    viewUserList [user1, user2, ..., usern] user2

-}
viewUserList : List User -> Maybe User -> Html Msg
viewUserList users selected =
    ul [ class "list-group" ]
        (makeUserRows users selected)


{-| Make user rows recursively
-}
makeUserRows : List User -> Maybe User -> List (Html Msg)
makeUserRows users selected =
    case users of
        [] ->
            []

        first :: more ->
            (case selected of
                Just selectedUser ->
                    if first.username == selectedUser.username then
                        UserList.viewSelectedUserRow first

                    else
                        UserList.viewUserRow first (UserSelected first)

                Nothing ->
                    UserList.viewUserRow first (UserSelected first)
            )
                :: makeUserRows more selected


{-| View chat bottom (input text and send button)
-}
viewBottom : Model -> Html Msg
viewBottom model =
    div
        [ class "row"
        , class "justify-content-end"
        ]
        [ div
            [ class "col-4"
            , css [ backgroundColor (hex "#ededed") ]
            ]
            []
        , viewInputArea model.userInput (isJust model.selectedUser)
        ]


{-| View chat input area (input text and send button)

    - The button is disabled if message is empty
    - The text field is disabled if no user is selected

-}
viewInputArea : String -> Bool -> Html Msg
viewInputArea message userIsSelected =
    div
        [ class "col-8"
        , css [ backgroundColor (hex "#ededed"), padding (Css.em 1) ]
        ]
        [ input
            [ class "form-text"
            , placeholder "Type a message"
            , css [ width (pct 80), fontSize (Css.em 1.2) ]
            , value message
            , readonly (not userIsSelected)
            , onInput InputChanged
            ]
            []
        , button
            [ class "btn"
            , class "btn-primary"
            , css [ float right ]
            , Html.Styled.Attributes.disabled (String.length message == 0)
            , onClick MessageSubmit
            ]
            [ text "Send" ]
        ]
