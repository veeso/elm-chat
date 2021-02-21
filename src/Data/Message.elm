--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.Message exposing (Conversation, Message, conversationDecoder, markMessageAsRead, messageDecoder, pushMessage)

-- Dependencies

import Iso8601
import Json.Decode exposing (Decoder, bool, field, list, map7, string)
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



-- Manipulation


{-| Push a message at the end of the conversation

    pushMessage [a, b, c] d -> [a, b, c, d]

-}
pushMessage : Conversation -> Message -> Conversation
pushMessage conversation newMessage =
    conversation ++ [ newMessage ]


{-| Mark message with provided ID as read

    markMessageAsRead [a, b] b -> a.read = ?, b.read = True

-}
markMessageAsRead : Conversation -> String -> Conversation
markMessageAsRead conversation msgId =
    case conversation of
        [] ->
            []

        first :: more ->
            (if first.id == msgId then
                { first | read = True }

             else
                first
            )
                :: markMessageAsRead more msgId



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
        (field "from" string)
        (field "to" string)
        (field "recv" bool)
        (field "read" bool)
