--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.WsMessage exposing (WsMessage, wsMessageDecoder)

import Data.Message
import Json.Decode exposing (Decoder, andThen, fail, field, map, map2, string, succeed)


{-| WsMessage variant
-}
type WsMessage
    = Delivery Data.Message.Message
    | Received String String -- Who ref
    | Read String String -- Who ref
    | Error String
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
    map2 Received
        (field "who" string)
        (field "ref" string)


{-| Decodes a "Read" websocket message (JSON)
-}
wsMessageReadDecoder : Decoder WsMessage
wsMessageReadDecoder =
    map2 Read
        (field "who" string)
        (field "ref" string)


{-| Decodes a "Error" websocket message (JSON)
-}
wsMessageErrorDecoder : Decoder WsMessage
wsMessageErrorDecoder =
    map Error
        (field "error" string)
