--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.Message exposing (Conversation, Message, conversationDecoder, messageDecoder)

-- Dependencies

import Iso8601
import Json.Decode exposing (Decoder, bool, field, list, map7, string)
import Json.Encode as Encode
import Time exposing (Posix)


{-| Conversation is an alias for a list of messages
-}
type alias Conversation =
    List Message


{-| Message describes a chat message entity

    - id : String: uuidv4, message identifier
    - date : Posix: message envoy datetime
    - body : String: Message body
    - sender : String: message sender
    - recipient : String: message recipient
    - recv : Bool
    - read : Bool: indicates whether the message has already been read (by the recipient)

-}
type alias Message =
    { id : String
    , datetime : Posix
    , body : String
    , sender : String
    , recipient : String
    , recv : Bool
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
    map7 Message
        (field "id" string)
        (field "datetime" Iso8601.decoder)
        (field "body" string)
        (field "sender" string)
        (field "recipient" string)
        (field "recv" bool)
        (field "read" bool)
