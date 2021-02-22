--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.WsMessage exposing (WsMessage(..), wsMessageDecoder)

import Data.Message
import Data.User exposing (User, userDecoder)
import Iso8601
import Json.Decode exposing (Decoder, andThen, bool, fail, field, map, map2, map3, string, succeed)
import Time exposing (Posix)


type alias UserRef =
    { who : String
    , ref : String
    }


type alias OnlineState =
    { username : String
    , online : Bool
    , lastActivity : Posix
    }


{-| WsMessage variant
-}
type WsMessage
    = Delivery Data.Message.Message
    | Received UserRef -- Who ref
    | Read UserRef -- Who ref
    | Error String
    | UserJoined User
    | UserOnline OnlineState
    | SessionExpired



-- Deserializer


{-| Decodes a websocket message (JSON) into WsMessage variant
-}
wsMessageDecoder : Decoder WsMessage
wsMessageDecoder =
    field "type" string |> andThen wsMessageTypeBasedDecoder


{-| Decodes a websocket message (JSON) based on the type field
-}
wsMessageTypeBasedDecoder : String -> Decoder WsMessage
wsMessageTypeBasedDecoder wsType =
    case wsType of
        "Delivery" ->
            wsMessageDeliveryDecoder

        "Received" ->
            wsMessageReceivedDecoder

        "Read" ->
            wsMessageReadDecoder

        "Error" ->
            wsMessageErrorDecoder

        "UserJoined" ->
            wsMessageUserJoinedDecoder

        "UserOnline" ->
            wsMessageUserOnlineDecoder

        "SessionExpired" ->
            succeed SessionExpired

        _ ->
            fail ("Unknown WS message type: " ++ wsType)


{-| Decodes a "Delivery" websocket message (JSON)
-}
wsMessageDeliveryDecoder : Decoder WsMessage
wsMessageDeliveryDecoder =
    map Delivery
        (field "message" Data.Message.messageDecoder)


{-| Decodes a "Received" websocket message (JSON)
-}
wsMessageReceivedDecoder : Decoder WsMessage
wsMessageReceivedDecoder =
    map Received wsUserRefDecoder


{-| Decodes a "Read" websocket message (JSON)
-}
wsMessageReadDecoder : Decoder WsMessage
wsMessageReadDecoder =
    map Read wsUserRefDecoder


{-| Decodes a "Error" websocket message (JSON)
-}
wsMessageErrorDecoder : Decoder WsMessage
wsMessageErrorDecoder =
    map Error
        (field "error" string)


{-| Decodes a UserJoined websoscket message (JSON)
-}
wsMessageUserJoinedDecoder : Decoder WsMessage
wsMessageUserJoinedDecoder =
    map UserJoined
        (field "user" userDecoder)


wsMessageUserOnlineDecoder : Decoder WsMessage
wsMessageUserOnlineDecoder =
    map UserOnline
        (map3 OnlineState
            (field "username" string)
            (field "online" bool)
            (field "lastActivity" Iso8601.decoder)
        )


{-| Decodes a user ref
-}
wsUserRefDecoder : Decoder UserRef
wsUserRefDecoder =
    map2 UserRef
        (field "who" string)
        (field "ref" string)
