--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Pages.Chat exposing (..)

import Data.Message as Messages
import Data.User exposing (User)
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
    | UserListMsg UserList.Msg
    | GotUsers (Result Http.Error (List User))
    | GotConversation (Result Http.Error Messages.Conversation)
    | MessageSent (Result Http.Error Messages.Message)
    | MarkedAsRead (Result Http.Error String)
    | Error Http.Error



-- TODO: Send command on Message submit


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputChanged newMsg ->
            ( { model | userInput = newMsg }, Cmd.none )

        -- Update message box
        MessageSubmit ->
            ( { model | userInput = "" }, Cmd.none )

        -- TODO: send message
        UserListMsg umsg ->
            case umsg of
                UserList.UserSelected user ->
                    ( { model | selectedUser = Just user, conversation = [] }, Cmd.none )

        -- Set user and clear conversation
        GotUsers result ->
            case result of
                Ok users ->
                    ( { model | users = users }, Cmd.none )

                -- Set users
                Err err ->
                    update (Error err) model

        GotConversation result ->
            case result of
                Ok conversation ->
                    ( { model | conversation = conversation }, Cmd.none )

                -- Set conversation; TODO: mark all messages as read
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



-- View
