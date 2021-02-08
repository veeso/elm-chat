--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.Message exposing (Conversation, Message, conversationDecoder)

-- Dependencies

import Date
import Json.Decode exposing (Decoder, andThen, bool, field, list, map6, string)
import Utils exposing (dateDecoder)


{-| Conversation is an alias for a list of messages
-}
type alias Conversation =
    List Message


{-| Message describes a chat message entity

    - id : String: uuidv4, message identifier
    - date : Date.Date: message envoy datetime
    - body : String: Message body
    - sender : String: message sender
    - recipient : String: message recipient
    - read : Bool: indicates whether the message has already been read (by the recipient)

-}
type alias Message =
    { id : String
    , datetime : Date.Date
    , body : String
    , sender : String
    , recipient : String
    , read : Bool
    }



-- Deserialization


{-| Decodes a JSON list of users into an Elm list of User
-}
conversationDecoder : Decoder Conversation
conversationDecoder =
    list messageDecoder


{-| Decodes a User entity from JSON and deserializes it into a User
-}
messageDecoder : Decoder Message
messageDecoder =
    map6 Message
        (field "id" string)
        (field "datetime" string |> andThen dateDecoder)
        (field "body" string)
        (field "sender" string)
        (field "recipient" string)
        (field "read" bool)
