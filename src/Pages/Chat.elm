--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Pages.Chat exposing (..)

import Css exposing (..)
import Data.Message as Messages
import Data.User as Users exposing (User)
import Data.WsMessage exposing (WsMessage)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, placeholder, readonly, value)
import Html.Styled.Events exposing (onClick, onInput)
import Http
import Json.Decode
import Ports
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
    | MarkedAsRecv (Result Http.Error String)
    | GotWsMessage String
    | ParsedWsMessage (Result Json.Decode.Error WsMessage)
    | SignOut
    | SignedOut (Result Http.Error ())
    | Error String
    | ErrorDismissed


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Input
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

        -- Users
        UserSelected user ->
            -- Select user; clear its inbox and download the conversation for it
            ( { model | selectedUser = Just (Users.clearUserInbox user), users = (Users.clearInboxSizeForUser model.users user.username), conversation = [] }, ApiMessages.getConversation user.username GotConversation )

        GotUsers result ->
            case result of
                Ok users ->
                    -- Once users have been loaded, start the WS channel
                    ( { model | users = users }, Ports.startChat () )

                -- Set users
                Err err ->
                    update (Error (fmtHttpError err Nothing)) model

        -- Messages
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

        MarkedAsRecv result ->
            case result of
                Ok msgid ->
                    ( { model | conversation = Messages.markMessageAsRecv model.conversation msgid }, Cmd.none )

                Err err ->
                    update (Error (fmtHttpError err Nothing)) model

        -- Sign out
        SignOut ->
            -- Send signout request
            ( model, ApiAuth.signout SignedOut )

        SignedOut result ->
            case result of
                Ok _ ->
                    -- Invalidate session and go to sign in
                    ( { model | session = Session.signOut model.session }, Route.replaceUrl (Session.getNavKey model.session) Route.SignIn )

                Err err ->
                    update (Error (fmtHttpError err Nothing)) model

        -- Error
        Error err ->
            ( { model | error = Just err }, Cmd.none )

        ErrorDismissed ->
            ( { model | error = Nothing }, Cmd.none )

        -- Websockets
        GotWsMessage body ->
            -- Parse ws message body
            update (ParsedWsMessage <| Json.Decode.decodeString Data.WsMessage.wsMessageDecoder body) model

        ParsedWsMessage result ->
            case result of
                Ok wsmessage ->
                    handleWsMessage model wsmessage

                Err error ->
                    -- Set error as string
                    update (Error <| Json.Decode.errorToString error) model


{-| Update model based on the WsMessage type

    handleWsMessage model mymsg -> model'

-}
handleWsMessage : Model -> WsMessage -> ( Model, Cmd Msg )
handleWsMessage model wsmessage =
    -- Switch over message type
    case wsmessage of
        Data.WsMessage.Delivery msg ->
            -- Add message to conversation if user is current, otherwise increment inbox size
            case model.selectedUser of
                Just sUser ->
                    if msg.sender == sUser.username then
                        -- Report message as read
                        ( { model | conversation = Messages.pushMessage model.conversation msg }, ApiMessages.markAsRead msg.id MarkedAsRead )

                    else
                        -- Report message as received
                        ( { model | users = Users.incrementInboxSizeForUser model.users msg.sender }, ApiMessages.markAsRecv msg.id MarkedAsRecv )

                Nothing ->
                    -- Report message as received
                    ( { model | users = Users.incrementInboxSizeForUser model.users msg.sender }, ApiMessages.markAsRecv msg.id MarkedAsRecv )

        Data.WsMessage.Received msgdata ->
            -- Set message as received, if conversation is active
            case model.selectedUser of
                Just sUser ->
                    if msgdata.who == sUser.username then
                        ( { model | conversation = Messages.markMessageAsRecv model.conversation msgdata.ref }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        Data.WsMessage.Read msgdata ->
            -- Set message as read, if conversation is active
            case model.selectedUser of
                Just sUser ->
                    if msgdata.who == sUser.username then
                        ( { model | conversation = Messages.markMessageAsRead model.conversation msgdata.ref }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        Data.WsMessage.Error err ->
            -- Write error in model
            update (Error err) model

        Data.WsMessage.UserJoined user ->
            -- Add user to user list; then sort again list by username
            ( { model | users = Users.sortUsers <| user :: model.users }, Cmd.none )

        Data.WsMessage.UserOnline state ->
            -- Change user state in list
            ( { model | users = Users.updateUserStatus model.users state.username state.online state.lastActivity }, Cmd.none )

        Data.WsMessage.SessionExpired ->
            -- Go back to login
            ( { model | session = Session.signOut model.session }, Route.replaceUrl (Session.getNavKey model.session) Route.SignIn )


{-| Mark all messages sent to us as read and notify remote

    notifyMessageRead [ a, b ] foo

-}
notifyMessageRead : Messages.Conversation -> String -> List (Cmd Msg)
notifyMessageRead conversation username =
    case conversation of
        [] ->
            []

        first :: more ->
            (if first.recipient == username && not first.read then
                ApiMessages.markAsRead first.id MarkedAsRead

             else
                Cmd.none
            )
                :: notifyMessageRead more username



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.chatMessageReceiver GotWsMessage



-- View


view : Model -> Html Msg
view model =
    div [ css [ height (vh 80) ] ]
        [ viewTopbar
        , div [ class "container-fluid", css [ height (pct 95) ] ]
            [ viewHeader model
            , viewErrorMessage model.error
            , viewChatBody model
            , viewBottom model
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
            , borderBottom3 (px 1) solid (hex "cccccc")
            , backgroundColor (hex "ededed")
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
        [ span [ css [ color (hex "aaaaaa") ] ] [ text (prettyDateFormatter Time.utc lastActivity) ]
        ]


{-| View the chat body (main body of the chat; users + messages)
-}
viewChatBody : Model -> Html Msg
viewChatBody model =
    div [ class "row", css [ height (pct 100) ] ]
        [ div [ class "col-4", css [ overflowY auto, overflowX hidden, padding (px 0) ] ]
            [ viewUserList model.users model.selectedUser
            ]
        , div [ class "col-8", css [ borderLeft3 (px 1) solid (hex "cccccc"), overflow auto, padding (px 0) ] ]
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
                        Html.Styled.map (\_ -> UserSelected first) (UserList.viewUserRow first)

                Nothing ->
                    Html.Styled.map (\_ -> UserSelected first) (UserList.viewUserRow first)
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
            , css [ backgroundColor (hex "ededed"), bottom (px 0), width (vw 100) ]
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
        , css [ backgroundColor (hex "ededed"), padding (Css.em 1) ]
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
