--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Request.Messages exposing (Msg(..), getConversation, markAsRead, sendMessage)

import Data.Message exposing (Conversation, Message, conversationDecoder, messageDecoder)
import Http
import Json.Encode as Encode


type Msg
    = GotConversation (Result Http.Error Conversation)
    | MessageSent (Result Http.Error Message)
    | MarkedAsRead (Result Http.Error ())


{-| Get conversation between current user and another
Current user is stored inside the JWT, so it's read by the server when you send the request automatically :D

    getConversation "foo"

-}
getConversation : String -> Cmd Msg
getConversation username =
    Http.get
        { url = ":3000/api/chat/history/" ++ username
        , expect = Http.expectJson GotConversation conversationDecoder
        }


{-| Send message to a certain user; returns the Message entity processed by the server

    sendMessage "omar" "Hello Omar! How are you?"

-}
sendMessage : String -> String -> Cmd Msg
sendMessage recipient text =
    let
        body =
            Encode.object
                [ ( "body", Encode.string text )
                ]
    in
    Http.post
        { url = ":3000/api/chat/send/" ++ recipient
        , body = Http.jsonBody body
        , expect = Http.expectJson MessageSent messageDecoder
        }


{-| Mark provided message as read

    getConversation "e13df554-55c3-4234-8f42-c6a560fbf5e7"

-}
markAsRead : String -> Cmd Msg
markAsRead msgId =
    Http.post
        { url = ":3000/api/chat/setread/" ++ msgId
        , body = Http.emptyBody
        , expect = Http.expectWhatever MarkedAsRead
        }
