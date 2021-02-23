--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Request.Messages exposing (getConversation, markAsRead, markAsRecv, sendMessage)

import Data.Message exposing (Conversation, Message, conversationDecoder, messageDecoder)
import Http
import Json.Encode as Encode


{-| Get conversation between current user and another
Current user is stored inside the JWT, so it's read by the server when you send the request automatically :D

    getConversation "foo"

-}
getConversation : String -> (Result Http.Error Conversation -> msg) -> Cmd msg
getConversation username msg =
    Http.get
        { url = "/api/chat/history/" ++ username
        , expect = Http.expectJson msg conversationDecoder
        }


{-| Send message to a certain user; returns the Message entity processed by the server

    sendMessage "omar" "Hello Omar! How are you?"

-}
sendMessage : String -> String -> (Result Http.Error Message -> msg) -> Cmd msg
sendMessage recipient text msg =
    let
        body =
            Encode.object
                [ ( "body", Encode.string text )
                ]
    in
    Http.post
        { url = "/api/chat/send/" ++ recipient
        , body = Http.jsonBody body
        , expect = Http.expectJson msg messageDecoder
        }


{-| Mark provided message as read

    getConversation "e13df554-55c3-4234-8f42-c6a560fbf5e7"

    Returns the message ID if Ok

-}
markAsRead : String -> (Result Http.Error String -> msg) -> Cmd msg
markAsRead msgId msg =
    Http.post
        { url = "/api/chat/setread/" ++ msgId
        , body = Http.emptyBody
        , expect =
            Http.expectStringResponse msg <|
                \response ->
                    case response of
                        Http.BadUrl_ url ->
                            Err (Http.BadUrl url)

                        Http.Timeout_ ->
                            Err Http.Timeout

                        Http.NetworkError_ ->
                            Err Http.NetworkError

                        Http.BadStatus_ metadata _ ->
                            Err (Http.BadStatus metadata.statusCode)

                        Http.GoodStatus_ _ _ ->
                            Ok msgId
        }


{-| Mark provided message as received

    getConversation "e13df554-55c3-4234-8f42-c6a560fbf5e7"

    Returns the message ID if Ok

-}
markAsRecv : String -> (Result Http.Error String -> msg) -> Cmd msg
markAsRecv msgId msg =
    Http.post
        { url = "/api/chat/setrecv/" ++ msgId
        , body = Http.emptyBody
        , expect =
            Http.expectStringResponse msg <|
                \response ->
                    case response of
                        Http.BadUrl_ url ->
                            Err (Http.BadUrl url)

                        Http.Timeout_ ->
                            Err Http.Timeout

                        Http.NetworkError_ ->
                            Err Http.NetworkError

                        Http.BadStatus_ metadata _ ->
                            Err (Http.BadStatus metadata.statusCode)

                        Http.GoodStatus_ _ _ ->
                            Ok msgId
        }
