--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Request.Messages exposing (getConversation, markAsRead)

import Data.Message exposing (Conversation, conversationDecoder)
import File exposing (File)
import Http exposing (emptyBody, filePart, multipartBody, stringPart)
import Json.Decode exposing (Decoder, andThen, field, string)
import Json.Encode as Encode


type Msg
    = GotConversation (Result Http.Error Conversation)
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
