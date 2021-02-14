--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Pages.Chat exposing (..)

import Data.Message exposing (Conversation)
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
    , conversation : Maybe Conversation -- The conversation I'm having with selected user
    , error : Maybe Http.Error
    }



-- Init TODO: send request to get users


init : User -> ( Model, Cmd ApiUsers.Msg )
init client =
    ( { userInput = ""
      , users = []
      , selectedUser = Nothing
      , client = client
      , conversation = Nothing
      , error = Nothing
      }
    , ApiUsers.getUsers
    )



-- Update --


type Msg
    = InputChanged String
    | MessageSubmit
    | UserListMsg UserList.Msg
    | MessagesMsg ApiMessages.Msg
    | UsersMsg ApiUsers.Msg
    | Error Http.Error



-- TODO: Send command on Message submit


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputChanged newMsg ->
            ( { model | userInput = newMsg }, Cmd.none )

        MessageSubmit ->
            ( { model | userInput = "" }, Cmd.none )

        UserListMsg umsg ->
            case umsg of
                UserList.UserSelected user ->
                    ( { model | selectedUser = Just user }, Cmd.none )

        MessagesMsg mmsg ->
            case mmsg of
                ApiMessages.GotConversation result ->
                    case result of
                        Ok conversation ->
                            ( { model | conversation = Just conversation }, Cmd.none )

                        Err err ->
                            update (Error err) model

        UsersMsg umsg ->
            case umsg of
                ApiUsers.GotUsers result ->
                    case result of
                        Ok users ->
                            ( { model | users = users }, Cmd.none )

                        Err err ->
                            update (Error err) model

        Error err ->
            ( { model | error = Just err }, Cmd.none )



-- View
