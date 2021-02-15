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
import Html.Styled.Attributes exposing (class, css)
import Http
import Request.Messages as ApiMessages
import Request.User as ApiUsers
import Views.UserList as UserList



-- Model --


type alias Model =
    { userInput : String
    , users : List User -- The list of users
    , selectedUser : Maybe User -- The user I've selected
    , client : User -- Who ami?
    , conversation : Messages.Conversation -- The conversation I'm having with selected user
    , error : Maybe Http.Error
    }



-- Init


init : User -> ( Model, Cmd Msg )
init client =
    ( { userInput = ""
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
    | Error Http.Error



-- Update


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
                    update (Error err) model

        GotConversation result ->
            case result of
                -- Set conversation; notify to server messages have been read NOTE: we don't mark conversation as read HERE, because we do later for each message in `MarkedAsRead`
                Ok conversation ->
                    ( { model | conversation = conversation }, Cmd.batch (notifyMessageRead conversation model.client.username) )

                Err err ->
                    update (Error err) model

        MessageSent result ->
            case result of
                Ok chatmsg ->
                    ( { model | conversation = Messages.pushMessage model.conversation chatmsg }, Cmd.none )

                Err err ->
                    update (Error err) model

        MarkedAsRead result ->
            case result of
                Ok msgid ->
                    ( { model | conversation = Messages.markMessageAsRead model.conversation msgid }, Cmd.none )

                Err err ->
                    update (Error err) model

        Error err ->
            ( { model | error = Just err }, Cmd.none )


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
-- TODO: DISABLED INPUT IF NO USER IS SELECTED
-- TODO: DISABLED BUTTON IF INPUT LENGTH IS 0


view : Model -> Html msg
view model =
    div [ class "container-fluid" ]
        [ viewHeader model
        ]


viewHeader : Model -> Html msg
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
        ]
