--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.Message exposing (Conversation, Message, conversationDecoder, encodeMessage, messageDecoder)

-- Dependencies

import Iso8601
import Json.Decode exposing (Decoder, bool, field, list, map6, string)
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
    - read : Bool: indicates whether the message has already been read (by the recipient)

-}
type alias Message =
    { id : String
    , datetime : Posix
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
        (field "datetime" Iso8601.decoder)
        (field "body" string)
        (field "sender" string)
        (field "recipient" string)
        (field "read" bool)


{-| Encodes a Message
-}
encodeMessage : Message -> Encode.Value
encodeMessage msg =
    Encode.object
        [ ( "id", Encode.string msg.id )
        , ( "body", Encode.string msg.body )
        , ( "body", Encode.string msg.body )
        , ( "datetime", Iso8601.encode msg.datetime )
        , ( "from", Encode.string msg.sender )
        , ( "to", Encode.string msg.recipient )
        ]
